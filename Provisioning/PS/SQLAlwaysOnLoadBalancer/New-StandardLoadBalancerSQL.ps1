$rgVnetName = "arsgryboinfeastusprd01"
$rgAppName = "arsgryboinfeastusprd01"
$lbName = "azlbiybodj6eastusprd01"
$vnetName = "avnetybospkeastusprd01"
$fepreffix = "lbife"
$bepreffix = "lbibe"
$appsuffix = "ybodj6eastusprd01"
$privateIP = '172.18.40.43'


## Place virtual network created in previous step into a variable. ##
$net = @{
    Name = $vnetName
    ResourceGroupName = $rgVnetName
}
$vnet = Get-AzVirtualNetwork @net

## Create load balancer frontend configuration and place in variable. ##
$lbip = @{
    Name = $fepreffix + $appsuffix
    PrivateIpAddress = $privateIP
    SubnetId = $vnet.Subnets[2].Id
}
$feip = New-AzLoadBalancerFrontendIpConfig @lbip

## Create backend address pool configuration and place in variable. ##
$bepool = New-AzLoadBalancerBackendAddressPoolConfig -Name "$($bepreffix + $appsuffix)"

## Create the health probe and place in variable. ##
$probe = @{
    Name = 'ILBPROBE_1433'
    Protocol = 'tcp'
    Port = '59999'
    IntervalInSeconds = '15'
    ProbeCount = '2'
}
$healthprobe = New-AzLoadBalancerProbeConfig @probe

## Create the load balancer rule and place in variable. ##
$lbrule = @{
    Name = 'ILBCR_1433'
    Protocol = 'tcp'
    FrontendPort = '1433'
    BackendPort = '1433'
    IdleTimeoutInMinutes = '4'
    FrontendIpConfiguration = $feip
    BackendAddressPool = $bePool
}
$rule = New-AzLoadBalancerRuleConfig @lbrule -EnableTcpReset

## Create the load balancer resource. ##
$loadbalancer = @{
    ResourceGroupName = $rgAppName
    Name = $lbName
    Location = 'eastus'
    Sku = 'Standard'
    FrontendIpConfiguration = $feip
    BackendAddressPool = $bePool
    LoadBalancingRule = $rule
    Probe = $healthprobe
}
New-AzLoadBalancer @loadbalancer