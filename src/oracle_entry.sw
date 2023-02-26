contract; 

use main::BountyBoard;

abi OracleEntry{
    fn process_response(response: bool, index: u64);
}

// todo!() - update with actual contract ID & Oracle Wallet 
const BOUNTY_BOARD = ContractId::from(0x79fa8779bed2f36c3581d01c79df8da45eee09fac1fd76a5a656e16326317ef0);
const ORACLE_ID = Address::from(fuel1cjet8pc6ulx02wkdnnm285w6pey2yw3wdmyvu0r8nhsjhpcuyu3q6he4gs);
impl OracleEntry for Contract{

    fn process_response(response: bool, index: u64){
        assert(msg_sender().unwrap() == ORACLE_ID);
        match response{
            true => {
                let bb = abi(OracleEntry, BOUNTY_BOARD);
                let return_value = bb.unlock_bounty();
            }
            false => revert(0),
        }
    }
}