contract; 

dep interface;
dep data_structures;
use interface::*;
use std::auth::msg_sender;
use data_structures::*;
abi OracleEntry{
    fn process_response(response: bool, index: u64, status: Status) -> (u64, Status);
}

// todo!() - update with actual contract ID & Oracle Wallet 
const BOUNTY_BOARD = 0x79fa8779bed2f36c3581d01c79df8da45eee09fac1fd76a5a656e16326317ef0;
const ORACLE_ID = Identity::Address(Address::from(0xf826361801dabe5766968368e06131f88f0a4ff60549594db6185f5b848592b5));
impl OracleEntry for Contract{

    fn process_response(response: bool, index: u64, status: Status) -> (u64, Status){
        assert(msg_sender().unwrap() == ORACLE_ID);
                let bb = abi(BountyBoard, BOUNTY_BOARD);
                let return_value = bb.unlock_bounty(index, status);
                (index, status)
        }
    }
