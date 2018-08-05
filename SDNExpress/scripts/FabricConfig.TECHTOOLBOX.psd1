﻿@{

    AllNodes = 
    @(
        @{ 
            NodeName="*"              # * indicates this section applies to all nodes.  Don't change it.
            
            InstallSrcDir="\\$env:Computername\SDNExpress"
            HostInstallSrcDir="\\$env:Computername\SDNExpress"

            #VM Creation variables
                        
            VHDName="WS2016-Dc-Core.vhdx"    # Name of the VHDX to use for VM creation. must exist in the images path under InstallSrcDir
            ProductKey="" # Can be blank if using a volume license, or you are deploying in eval mode.  (Don't forget to press "skip").

            #Update to a local path on the hyper-v hosts if local storage, or a UNC path for shared storage  
            VMLocation="E:\NotBackedUp\VMs"                               #Example: "C:\ClusterStorage\Volume1\VMs"

            #User account with permission to add computers to the domain.  Username must not contain the domain.  
            DomainJoinUsername = 'setup-sdn'                              #Example: "AlYoung"
            DomainJoinPassword = '{guess}'                                #Example: "V3ryC0mplex4dminP4ssword"
            LocalAdminPassword = '{guess}'                                #Example: "V3ryC0mplexP4ssword"

            #This is the FQDN that the Network Controller's REST IP is assigned to.
            #IMPORTANT: This name must be manually added to your DNS server and map to the NetworkControllerRestIP
            NetworkControllerRestName = "nc01.$env:USERDNSDOMAIN".ToLower()    #Example (after evaluation of $env:USERDNSDOMAIN): myname.contoso.com
            NetworkControllerRestIP = "10.1.30.4"                              #Example: 10.20.30.40
            NetworkControllerRestIPMask = "24"                                 #Example: 24
           
            #This is the name of the virtual switch that must exist on each host.  Note: if you have any 
            #Hyper-V hosts which virtual switches that are named differently, you can override this variable
            #by adding it to the "HyperVHost" role nodes as needed.
            vSwitchName = "Embedded Team Switch"                          #Example: SDNSwitch

            #This is the user account and password that the Service Fabric cluster nodes will use for communicating with each other
            #The NCClusterUsername must contain the Domain name in the format DOMAIN\User
            NCClusterUsername = "$env:USERDOMAIN\s-nc01-cluster"       #Example: CONTOSO\AlYoung
            NCClusterPassword = '{guess}'                                 #Example: MySuperS3cretP4ssword

            #This is the user account and password that is used for communicating with the Gateway VMs
            #The HostUsername must contain the Domain name in the format DOMAIN\User
            HostUsername = "$env:USERDOMAIN\s-nc01-host"               #Example: CONTOSO\al
            HostPassword = '{guess}'                                      #Example: MySuperS3cretP4ssword
            
            #iDNS configuration - the iDNSAdminUsername must be a AD user who is a member of the DNSAdmins group. This can be same user as
            #the DomainJoinUsername above as long as they are also a member of DNSAdmins group. The iDNSAddress is the IP address of your DNS server
            #on the Management network and it must be an address which is reachable from the Network Controller nodes.
            iDNSAdminUsername = 'setup-sdn'                               #Example: "AlYoung"
            iDNSAdminPassword = '{guess}'                    #Example: "V3ryC0mplex4dminP4ssword"
            iDNSAddress= '10.1.30.2'                                      #Example: "10.0.0.7"
            iDNSZoneName = $env:USERDNSDOMAIN.ToLower()                   #Example: "contoso.local"
            iDNSMacAddress = 'AA-BB-CC-AA-BB-CC'
            iDNSCredentialResourceId = 'c6abefg6-44fb-45f6-89ec-5ebd890a144f' 

            #Required for remotely setting cert file ACLs. This should not be changed.
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true

            #This next section defines the logical networks that will be created in the network controller once it is deployed and running
            #The same subnet can be used for multiple logical networks as long as the PoolStart and PoolEnd do not overlap for any of them
            #If your networks are untagged/access mode networks with no VLAN, then specify VLANID of 0 for those networks.
            LogicalNetworks = @(
                @{
                    Name = "HNVPA"
                    ResourceId = 'bb6c6f28-bad9-441b-8e62-57d2be255904'
                    NetworkVirtualization = $true
                    Subnets = @(
                        @{
                            VLANID = "31"                                 #Example: 11 
                            AddressPrefix = "10.1.31.0/24"                #Example: "10.0.10.0/24"
                            DNS = @("10.1.30.2", "10.1.30.3")             #Example: @("10.0.0.7", "10.0.0.8", "10.0.0.9")
                            Gateways = @("10.1.31.1")                     #Example: @("10.0.10.1")
                            PoolStart = "10.1.31.50"                      #Example: "10.0.10.50"
                            PoolEnd = "10.1.31.150"                       #Example: "10.0.10.150"
                       }
                    )
                },    
                @{
                    Name = "PublicVIP"
                    ResourceId = 'f8f67956-3906-4303-94c5-09cf91e7e311'
                    Subnets = @(
                        @{
                            # Note: "Spoof" public VIP addresses with private 172.28.6.x addresses
                            # (due to limited availability of public IPv4 addresses)
                            AddressPrefix = "172.28.6.0/28"               #Example: "10.0.20.0/24"
                            Gateways = @("172.28.6.1")                    #Example: @("10.0.20.1")
                            PoolStart = "172.28.6.2"                      #Example: "10.0.20.5"
                            PoolEnd = "172.28.6.14"                       #Example: "10.0.20.100"
                            IsPublic = $true
                            IsVipPool = $true
                        }  
                    )
                },
                @{
                    #The first IP address (PoolStart) for this logical network is automatically assigned to the SLB Manager.  
                    Name = "PrivateVIP"
                    ResourceId = '0a386df6-5c5e-48bb-ab4b-709659aaa85a'
                    Subnets = @(
                        @{
                            AddressPrefix = "192.168.50.0/24"             #Example: "10.0.50.0/24"
                            Gateways = @("192.168.50.1")                  #Example: @("10.0.50.1")
                            PoolStart = "192.168.50.5"                    #Example: "10.0.50.5"
                            PoolEnd = "192.168.50.100"                    #Example: "10.0.50.100"
                            IsVipPool = $true
                        }
                    )
                },
                @{
                    Name = "GreVIP"
                    ResourceId = 'f8f67956-3906-4303-94c5-09cf91e7e33'
                    Subnets = @(
                        @{  ## Gre GW's VIP Subnet
                            AddressPrefix = "192.168.51.0/24"             #Example: "10.0.30.0/24"                  
                            Gateways = @("192.168.51.1")                  #Example: @("10.0.30.1")
                            PoolStart = "192.168.51.5"                    #Example: "10.0.30.5"
                            PoolEnd = "192.168.51.100"                    #Example: "10.0.30.100"
                        }
                    )
                },
                @{
                    Name = "Transit"
                    ResourceId = '00000000-2222-1111-9999-000000000001'
                    Subnets = @(
                        @{
                            VLANID = "32"                                 #Example: 12
                            AddressPrefix = "10.1.32.0/24"                #Example: "10.0.40.0/24"
                            Gateways = @("10.1.32.1")                     #Example: @("10.0.40.1")
                            PoolStart = "10.1.32.20"                      #Example: "10.0.40.5"
                            PoolEnd = "10.1.32.100"                       #Example: "10.0.40.100"
                        }  
                    )
                },    
                @{
                    Name = "Management"
                    ResourceId = '00000000-2222-1111-9999-000000000002'
                    Subnets = @(
                        @{
                            VLANID = "30"                                 #Example: 7                        
                            AddressPrefix = "10.1.30.0/24"                #Example: "10.0.0.0/24"
                            DNS = @("10.1.30.2", "10.1.30.3")             #Example: @("10.0.0.7", "10.0.0.8", "10.0.0.9")
                            Gateways = @("10.1.30.1")                     #Example: @("10.0.40.1")
                            PoolStart = "10.1.30.19"                      #Example: "10.0.0.5"
                            PoolEnd = "10.1.30.19"                        #Example: "10.0.0.100"
                        }  
                    )
                }
            )

            # Gateway Pool definitions
            # Do not modify
            GatewayPools = @(
                @{
                    ResourceId = "default"
                    Type = "All"
                    Capacity = "10000"				    #Example: 10000000 # for 10 GB
                    RedundantGatewayCount = "1"                   #Example: 2        # for 2 Redundant Gateways
                },
                @{
                    ResourceId = "GrePool"
                    Type = "S2sGre"
                    Capacity = "10000"				    #Example: 10000000 # for 10 GB
                    RedundantGatewayCount = "1"                   #Example: 2        # for 2 Redundant Gateways
                }
            )

            #This section defines the BGP Peer information.  This information is usually obtained from your physical 
            #switch configuration or must be provided to you by your network administrator.
            
            #This is used by the network controller only and does not need to be changed
            MuxPeerRouterName = 'BGPGateway-0'
            
            #MuxPeerRouterIP is typically the default gateway IP for the HNV PA network. 
            MuxPeerRouterIP = '10.1.31.1'                                #Example: "10.0.10.1"
            
            #This is the ASN that is assigned to the physical router.  If BGP is used throughout your core network you must
            #coordinate with your network administrators to use an appropriate value.  If this is an island then you choose your
            #own values.
            MuxPeerRouterASN = '1'                                        #Example: "1"
            
            #This is the ASN that is assigned to the SLB MUXes and Gateways.  If BGP is used throughout your core network you must
            #coordinate with your network administrators to use an appropriate value.  The physical router must be configured
            #to accept peering connections from this ASN.
            MuxASN = '2'                                         #Example: "2"

            #This section defines the BGP peerinf information for the GRE gateway.  If your BGP gateways use the same physical routers
            #as the muxes then you can use the same values, otherwise you will need to specify the values that are defined for the routers
            #that are serving the GRE gateways.
            GreBgpPeerRouterIP = '10.1.31.1'                              #Example: "10.0.10.1"
            GreBgpPeerRouterASN = '1'                                     #Example: "1"
            GreBgpRouterASN = '3'                                         #Example: "2"
            
            #This is the public IP address that is assigned to the Site-to-site gateway pool.  It must come from the public VIP logical
            #network pool defined above.
            GatewayPublicIPAddress = "172.28.6.3"                         #Example: 10.0.20.6

            #Time and Locale information for VMs
            #If these are not specified, it will use the timezone and locale of the host where a VM is created.
            #TimeZone = '<< Replace >>'                                      #Example: Pacific Standard Time
            #Locale='<< Replace >>'                                          #Example: en-US

            #You generally don't need to change the rest of the values in this section

            VHDSrcLocation="Images"                                         #Must be under InstallSrcDir
            ToolsSrcLocation="Tools"                                        #Must be under InstallSrcDir
            CertFolder="Certs"                                              #Must be under InstallSrcDir
            NCCertName="NetworkControllerRootCertificate.cer"               #Will be generated on NC and placed in CertFolder

            #These are locations that exist on the hyper-v host or in VMs that will get created as needed
            MountDir="C:\Temp"                                                                
            ToolsLocation = "c:\Tools"

            VMMACAddressPoolStart = "00-1D-D8-00-00-00"
            VMMACAddressPoolEnd = "00-1D-D8-00-00-FF"

            MACAddressPoolStart = "00-1D-D8-B7-1C-00"
            MACAddressPoolEnd = "00-1D-D8-F4-1F-FF"

            #ResourceIDs that will be used.  These are global to the controller  
            NCCredentialResourceId = 'c6abefb6-24ab-45f6-80ec-5ebd690a544f'
            HostCredentialResourceId = 'b6a1d5d6-5e1a-4f63-982d-c3da2ad54ee2'
            MACAddressPoolResourceId = '8197fd09-8a69-417e-a55c-10c2c61f5ee7'
            PublicIPResourceId = '00000000-5555-0000-0001-000000000000'

            #By default this will use the same AD domain as the deployment machine.  Don't change this.
            FQDN=$env:USERDNSDOMAIN

            #Version of this config file. Don't change this.
            ConfigFileVersion="1.2"
         },

        #You will define one node for each Hyper-V host in your environment.  A few are provided as examples, but 
        #you can add and remove them as needed.  If you remove nodes, you will need to reorganize the VMs sections so each
        #of the VMs you will be creating are assigned to a host.
        @{ 
            #This is the name of the first Hyper-V host to use for SDN workloads.  It does not include the FQDN.
            NodeName="TT-HV05A"                                #Example: "Host-01"
            Role="HyperVHost"
            VMs=@(
              @{ 
                VMName="TT-NC01A"                              #Example: "NC-01"
				VMMemory=4GB                                   #Example: 4GB
                NICs=@(
                    @{
                        IPAddress="10.1.30.5"                  #Example: "10.0.0.10"
                        LogicalNetwork = "Management"
                    }
                )
              },
              @{    
                VMName="TT-MUX01A"                             #Example: "MUX-01"
				VMMemory=4GB                                   #Example: 4GB
                NICs=@(
                    @{
                        IPAddress="10.1.30.8"
                        LogicalNetwork = "Management"
                    },
                    @{
                        IPAddress="10.1.31.2"                  #Example: "10.0.10.10"
                        LogicalNetwork = "HNVPA"
                    },
                    @{
                        IPAddress="10.1.32.2"
                        LogicalNetwork = "Transit"
                    }
                )
              },
              @{ 
                VMName="TT-MTGW01A"                            #Example: "MTGW-01"
				VMMemory=4GB                                   #Example: 4GB
                VMRole = "Gateway"

                NICs=@(
                    @{
                        IPAddress="10.1.30.10"                 #Example: "10.0.0.10"
                        LogicalNetwork = "Management"
                    },
                    @{
                        LogicalNetwork = "HNVPA"
                    },
                    @{
                        IPAddress="10.1.32.4"                  #Example: "10.0.0.13"
                        LogicalNetwork = "Transit"
                    }
                )

              }
            )
         },
         @{ 
            NodeName="TT-HV05B"                                #Example: "Host-02"
            Role="HyperVHost"
            VMs=@(
              @{ 
                VMName="TT-NC01B"                              #Example: "NC-02"
				VMMemory=4GB                                   #Example: 4GB
                NICs=@(
                    @{
                        IPAddress="10.1.30.6"                  #Example: "10.0.0.12"
                        LogicalNetwork = "Management"
                    }
                )
              },
              @{ 
                VMName="TT-MUX01B"                             #Example: "MUX-02"
				VMMemory=4GB                                   #Example: 4GB
                NICs=@(
                    @{
                        IPAddress="10.1.30.9"
                        LogicalNetwork = "Management"
                    },
                    @{
                        IPAddress="10.1.31.3"
                        LogicalNetwork = "HNVPA"
                    },
                    @{
                        IPAddress="10.1.32.3"
                        LogicalNetwork = "Transit"
                    }
                )
              },
              @{ 
                VMName="TT-MTGW-GRE01A"                        #Example: "MTGW-02"
				VMMemory=4GB                                   #Example: 4GB
                VMRole = "Gateway"

                NICs=@(
                    @{
                        IPAddress="10.1.30.12"                 #Example: "10.0.0.13"
                        LogicalNetwork = "Management"
                    },
                    @{
                        LogicalNetwork = "HNVPA"
                    },
                    @{
                        IPAddress="10.1.32.6"                  #Example: "10.0.0.13"
                        LogicalNetwork = "Transit"
                    }
                )
              }
            )
         },
         @{ 
            NodeName="TT-HV05C"                                #Example: "Host-03"
            Role="HyperVHost"
            VMs=@(
              @{ 
                VMName="TT-NC01C"                              #Example: "NC-03"
				VMMemory=4GB                                   #Example: 4GB
                NICs=@(
                    @{
                        IPAddress="10.1.30.7"                  #Example: "10.0.0.14"
                        LogicalNetwork = "Management"
                    }
                )
              },
              @{ 
                VMName = "TT-MTGW01B"
				VMMemory=4GB
                VMRole = "Gateway"

                NICs=@(
                    @{
                        IPAddress="10.1.30.11"                  #Example: "10.0.0.13"                          
                        LogicalNetwork = "Management"
                    },
                    @{
                        LogicalNetwork = "HNVPA"
                    },
                    @{
                        IPAddress="10.1.32.5"                  #Example: "10.0.0.13"
                        LogicalNetwork = "Transit"
                    }
                )

              },
              @{ 
                VMName = "TT-MTGW-GRE01B"
				VMMemory=4GB
                VMRole = "Gateway"

                NICs=@(
                    @{
                        IPAddress="10.1.30.13"                 #Example: "10.0.0.13"
                        LogicalNetwork = "Management"
                    },
                    @{
                        LogicalNetwork = "HNVPA"
                    },
                    @{
                        IPAddress="10.1.32.7"                  #Example: "10.0.0.13"
                        LogicalNetwork = "Transit"
                    }
                )
              }			  
            )
         },
         @{ 
            NodeName="TT-NC01A"                                #Example: "NC-01"
            Role="NetworkController"
         },
         @{ 
            NodeName="TT-NC01B"                                #Example: "NC-02"
            Role="NetworkController"
         },
         @{ 
            NodeName="TT-NC01C"                                #Example: "NC-03"
            Role="NetworkController"
         },
         @{ 
            NodeName="TT-MUX01A"                               #Example: "MUX-01"
            Role="SLBMUX"
            InternalNicName="HNVPA"
         },
         @{ 
            NodeName="TT-MUX01B"                               #Example: "MUX-02"
            Role="SLBMUX"
            InternalNicName="HNVPA"
         },         
         @{ 
            NodeName="TT-MTGW01A"                              #Example: "MTGW-01"
            Role     = "Gateway"
            GatewayPoolResourceId = "default"
            InternalNicName = "HNVPA"
            ExternalNicName = "Transit"
         },
         @{  
            NodeName = "TT-MTGW01B"                            #Example: "MTGW-03"
            Role     = "Gateway" 
            GatewayPoolResourceId = "default" 
            InternalNicName = "HNVPA"
            ExternalNicName = "Transit"
         },
         @{ 
            NodeName="TT-MTGW-GRE01A"                          #Example: "MTGW-02"
            Role     = "Gateway"
            GatewayPoolResourceId = "GrePool"
            InternalNicName = "HNVPA"
            ExternalNicName = "Transit"
         },
         @{ 
            NodeName = "TT-MTGW-GRE01B"                        #Example: "MTGW-04"
            Role     = "Gateway" 
            GatewayPoolResourceId = "GrePool" 
            InternalNicName = "HNVPA"
            ExternalNicName = "Transit"
         }
     );
}
