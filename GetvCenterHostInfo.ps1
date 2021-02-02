# vCenter情報
$vcenter_name = "vcsa01.home"
$vcenter_domain = '@vc.home'

$vcenter_user = 'view'+ $vcenter_domain
$vcenter_pw = 'view'

# 結果出力ファイル
# ESXiホストリソースサマリ
$result_path = "./"

$f_host_result = Join-Path $result_path "esx_free_resource.csv"

# ホスト簡易 + ゲスト一覧
$f_guest_result = Join-Path $result_path  "esx_free_resource_with_guest.csv"

# vCenterに接続 ----- * ----- * ----- * ----- * ----- * ----- *
# -ForceでSSLのセキュリティ警告を無視
Connect-VIServer -Server $vcenter_name -User $vcenter_user -Password $vcenter_pw -Force > $null

$all_vmguest = Get-VM

$esx_hosts_ary = @{}
$esx_hosts = Get-VMHost
$esx_hosts | ForEach-Object {
    $esx = $_

    # ホスト名
    $esx_hostname = $esx.Name

    # ホストリソース情報  ----- * ----- * ----- * ----- * ----- *
    # 保有CPU数
    $cpu_num = $esx.NumCpu
    # 保有メモリ(GB)小数点第2位四捨五入
    $mem_totalGB = [Math]::Round($esx.MemoryTotalGB, 1,[MidpointRounding]::AwayFromZero)

    # クラスタ情報
    $belong_cluster = $esx.Parent.Name
    $cpu_name = $esx.ProcessorType

    # HW情報
    $Manufacturer = $esx.Manufacturer
    # 出力にカンマが含まれる場合はダブルクォーテーションを付与し、Excel等で表示がずれないようにする
    if($Manufacturer -match ","){
        $Manufacturer = "`"$Manufacturer`""
    }

    $Model = $esx.Model

    $esx_hosts_ary[$esx_hostname] = @{}
    $esx_hosts_ary[$esx_hostname]['cpu_num'] =        $cpu_num
    $esx_hosts_ary[$esx_hostname]['mem_totalGB'] =    $mem_totalGB
    $esx_hosts_ary[$esx_hostname]['belong_cluster'] = $belong_cluster
    $esx_hosts_ary[$esx_hostname]['cpu_name'] =       $cpu_name.Trim()
    $esx_hosts_ary[$esx_hostname]['Manufacturer'] =   $Manufacturer
    $esx_hosts_ary[$esx_hostname]['Model'] =          $Model

    # ESXiの空きリソース算出の為、対象のESXiに搭載されているゲストのリソース情報を取得
    $esx_hosts_ary[$esx_hostname]['guest'] = @{}
    $esx_guests = $all_vmguest | Where-Object {$_.VMhost -match $esx_hostname}
    $esx_guests | ForEach-Object {

        # ゲストリソース情報  ----- * ----- * ----- * ----- * ----- *
        $esx_guest = $_
        # ゲスト名
        $name = $esx_guest.Name
        # ゲスト電源状態(0:powerOff/1:powerOn)
        $powerstate = $esx_guest.PowerState
        # 割り当てCPU数
        $assigned_cpu = $esx_guest.NumCpu
        # 割り当てメモリ(GB)小数点第4位四捨五入
        $assigned_mem = [Math]::Round($esx_guest.MemoryGB, 3,[MidpointRounding]::AwayFromZero)

        $esx_hosts_ary[$esx_hostname]['guest'][$name] = @{}
        $esx_hosts_ary[$esx_hostname]['guest'][$name]['powerstate']   = $powerstate
        $esx_hosts_ary[$esx_hostname]['guest'][$name]['assigned_cpu'] = $assigned_cpu
        $esx_hosts_ary[$esx_hostname]['guest'][$name]['assigned_mem'] = $assigned_mem

    }

    # 収集した情報からホストの純粋な空きリソースを算出
    # cpu/mem
    $total_assigned_cpu = ""
    $total_assigned_mem = ""

    $esx_hosts_ary[$esx_hostname]['guest'].Values | ForEach-Object {
        $total_assigned_cpu = $_.assigned_cpu + $cpu
        $total_assigned_mem = $_.assigned_mem + $total_assigned_mem
    }
    $esx_hosts_ary[$esx_hostname]['cpu_free']   = $esx_hosts_ary[$esx_hostname]['cpu_num']     - $total_assigned_cpu
    $esx_hosts_ary[$esx_hostname]['mem_freeGB'] = $esx_hosts_ary[$esx_hostname]['mem_totalGB'] - $total_assigned_mem

    # ゲスト搭載数
    $esx_hosts_ary[$esx_hostname]['guest_num'] = $esx_hosts_ary[$esx_hostname]['guest'].Keys.Count
}

# 結果出力(ESXiホスト)  ----- * ----- * ----- * ----- * ----- *

# ホスト空き一覧データ ----- * ----- * ----- * ----- *
# 搭載ESXiを決めるのに必要そうな情報を表示する。
# ESXiホスト名順に表示

# ヘッダ
$header=(
    "# HostName"   ,
    "TotalCPU"     ,
    "FreeCPU"      ,
    "TotalMemGB"   ,
    "FreeMemGB"    ,
    "Guest_Num"    ,
    "Cluster"      ,
    "Cpu_Name"     ,
    "Manufacturer" ,
    "Model"
) -join ","

$header | Out-File -Width 9999 -Encoding utf8 $f_host_result

$esx_hosts_ary.Keys | Sort-Object | ForEach-Object {   
    $body=(
        $_                                    ,
        $esx_hosts_ary[$_]['cpu_num']         ,
        $esx_hosts_ary[$_]['cpu_free']        ,
        $esx_hosts_ary[$_]['mem_totalGB']     ,
        $esx_hosts_ary[$_]['mem_freeGB']      ,
        $esx_hosts_ary[$_]['guest_num']       ,
        $esx_hosts_ary[$_]['belong_cluster']  ,
        $esx_hosts_ary[$_]['cpu_name']        ,
        $esx_hosts_ary[$_]['Manufacturer']    ,
        $esx_hosts_ary[$_]['Model']
    ) -join ","

    $body | Out-File -Append -Width 9999 -Encoding utf8 $f_host_result

}

# ホスト+搭載ゲスト ----- * ----- * ----- * ----- *
# 人間向け簡易表示。どのホストにどのゲストが乗っているのか知りたいときに利用想定
# ホスト簡易 + ゲスト一覧

# 初期化
$null | out-file -Encoding utf8 $f_guest_result

$esx_hosts_ary.Keys | Sort-Object | ForEach-Object {
    $esx_hostname = $_
    Write-Output($esx_hostname + " ----- * ----- * ----- * ----- * ----- * ----- * ----- ")    | Out-File -Append -Width 9999 -Encoding utf8 $f_guest_result
    Write-Output("{0,-12}" -f "TotalCPU: "   + $esx_hosts_ary[$esx_hostname]['cpu_num'])       | Out-File -Append -Width 9999 -Encoding utf8 $f_guest_result
    Write-Output("{0,-12}" -f "FreeCPU: "    + $esx_hosts_ary[$esx_hostname]['cpu_free'])      | Out-File -Append -Width 9999 -Encoding utf8 $f_guest_result
    Write-Output("{0,-12}" -f "TotalMemGB: " + $esx_hosts_ary[$esx_hostname]['mem_totalGB'])   | Out-File -Append -Width 9999 -Encoding utf8 $f_guest_result
    Write-Output("{0,-12}" -f "FreeMemGB: "  + $esx_hosts_ary[$esx_hostname]['mem_freeGB'])    | Out-File -Append -Width 9999 -Encoding utf8 $f_guest_result
    Write-Output("{0,-12}" -f "Cluster: "    + $esx_hosts_ary[$esx_hostname]['belong_cluster'])| Out-File -Append -Width 9999 -Encoding utf8 $f_guest_result
    Write-Output('')                                                                           | Out-File -Append -Width 9999 -Encoding utf8 $f_guest_result
    Write-Output("{0,-12}" -f "GuestNum: "   + $esx_hosts_ary[$esx_hostname]['guest_num'])     | Out-File -Append -Width 9999 -Encoding utf8 $f_guest_result
    Write-Output($esx_hostname + " GuestInfomation ----- * ")                                  | Out-File -Append -Width 9999 -Encoding utf8 $f_guest_result
    
    $guest_header=(
    "# Name"        ,
    "Assigned_CPU"  ,
    "Assigned_MemGB"  ,
    "Powerstate"
    ) -join ","

    $guest_header| Out-File -Append  -Width 9999 -Encoding utf8 $f_guest_result

    $esx_hosts_ary[$esx_hostname]['guest'].Keys| ForEach-Object{
        $name = $_ 

        $guest_body=(
        $name,
        $esx_hosts_ary[$esx_hostname]['guest'][$name]['assigned_cpu'],
        $esx_hosts_ary[$esx_hostname]['guest'][$name]['assigned_mem'],
        $esx_hosts_ary[$esx_hostname]['guest'][$name]['powerstate']
        ) -join ","

        $guest_body| Out-File -Append -Width 9999 -Encoding utf8 $f_guest_result
    }
    Write-Output('') | Out-File -Append -Width 9999 -Encoding utf8 $f_guest_result
}


# vCenterから切断   ----- * ----- * ----- * ----- * ----- *
Disconnect-VIServer -Server $vcenter_name -Confirm:$false