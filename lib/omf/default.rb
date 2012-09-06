module OMF
  module Experiments
    module DefaultApplicationResults
      class IPerfResults < GenericResults
        class IPerfUDPRichInfo < GenericResults::DataGenerated
          set_table_name('iperf_UDP_Rich_Info')
        end
        class IPerfUDPPeriodicInfo < GenericResults::DataGenerated
          set_table_name('iperf_UDP_Periodic_Info')
        end
        class IPerfPeerInfo < GenericResults::DataGenerated
          set_table_name('iperf_Peer_Info')
        end
      
        def initialize(id)
          super(id)
        end
      end

      class OTGResults < GenericResults
        class OTGUDPOut < GenericResults::DataGenerated
          set_table_name('otg2_udp_out')
        end
        class OTRUDPIn < GenericResults::DataGenerated
          set_table_name('otr2_udp_in')
        end
      end
    end
  end
end
