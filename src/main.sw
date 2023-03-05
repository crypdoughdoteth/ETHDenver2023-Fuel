contract;

dep events;
dep data_structures;
dep interface;
use interface::*;
use data_structures::*;
use events::*;
use std::call_frames::{
    msg_asset_id,
    get_contract_id_from_call_frame,
};
use std::storage::{StorageVec, StorageMap};
use std::revert::revert;
use std::auth::msg_sender;
use std::logging::log;
use std::{context::*, token::*};
use std::block::timestamp;

const ORACLE_CONTRACT: Identity = Identity::ContractId(ContractId::from(0x79fa8779bed2f36c3581d01c79df8da45eee09fac1fd76a5a656e16326317ef0));

storage {
    //hard code oracle or change from constructor 
    #[storage(read, write)]
    bounties: StorageVec<Bounty> = StorageVec{},
}
impl BountyBoard for Contract {
    #[storage(read, write), payable]
    fn new(type_of: Bounties, issue: str[64], offer: u64, time: u64, tier: Tier){
       assert(msg_amount() >= offer);
       match tier {
        Tier::gold => assert(msg_amount() > 420 /*&& msg_asset_id() ==*/   ),
        Tier::silver => assert(msg_amount() > 250),
        Tier::bronze => assert(msg_amount() > 69),

       }
       let bty = Bounty{
            status: Status::available,
            issuer: msg_sender().unwrap(),
            assignees: Option::None,
            asset_id: msg_asset_id(),
            bounty_type: type_of,
            github_issue: issue,
            github_pull_request: Option::None,
            amount: msg_amount(),
            dispute_window: timestamp() + time,
            tier,
        };
        storage.bounties.push(bty);
        log(BountyCreated{bounty: bty});
    }
    #[storage(read, write)]
    fn attempt_bounty(index: u64, bounty_hunters: [Identity;4], pr: str[64]) {
        // ensure that the bounty is of type open, otherwise need to call the other function
        let bounty = storage.bounties.get(index).unwrap();
        match bounty.bounty_type{
            Bounties::open => (),
            Bounties::closed => revert(0),
        }
        // assign bounty
        let update_bounty = Bounty {
            status: Status::in_progress,
            issuer: bounty.issuer,
            asset_id: bounty.asset_id,
            assignees: Option::Some(bounty_hunters),
            bounty_type: bounty.bounty_type,
            github_issue: bounty.github_issue,
            github_pull_request: Option::Some(pr),
            amount: bounty.amount,
            dispute_window: bounty.dispute_window,
            tier: bounty.tier,
        };
        storage.bounties.set(index, update_bounty);
        // emit event
        log(BountyAssigned{users: bounty_hunters});
    }
     #[storage(read, write)]
    fn assign_bounty(index: u64, bounty_hunters: [Identity;4], pr: str[64]) {
        let bounty = storage.bounties.get(index).unwrap();
        // ensure the issuer of the bounty is the only one who can call this function
        assert(msg_sender().unwrap() == bounty.issuer);        
        //  assign bounty 
        let update_bounty = Bounty {
            status: Status::in_progress,
            issuer: bounty.issuer,
            asset_id: bounty.asset_id,
            assignees: Option::Some(bounty_hunters),
            bounty_type: bounty.bounty_type,
            github_issue: bounty.github_issue,
            github_pull_request: Option::Some(pr),
            amount: bounty.amount,
            dispute_window: bounty.dispute_window,
            tier: bounty.tier,
        };
        storage.bounties.set(index, update_bounty);
        //  emit event
        log(BountyAssigned{users: bounty_hunters});
    }

    //reassignment funtion

    #[storage(read, write)]
    fn settle_bounty(index: u64) {
        //only callable if assigned to a bounty
        // emit event that the Oracle tracks: make API call to github -> write to this contract again
        let bounty = storage.bounties.get(index).unwrap();
        match bounty.status {
            Status::in_progress => (),
            _ => revert(0),
        }        
        log(QueryOracle{bounty});   
        //emit event
    }
    #[storage(read, write)]
    fn unlock_bounty(index: u64, status: Status) {
        //this will be called by the oracle only, guard fn accordingly with assert
        //only call if state change => true 
        //oracle will call the github API to check state of the pull request. If PR is merged => set completed in the struct to true
        let sender = msg_sender().unwrap();

        assert(sender == ORACLE_CONTRACT);

        let bounty = storage.bounties.get(index).unwrap();
        let updated = Bounty {
            status: status,
            issuer: bounty.issuer,
            asset_id: bounty.asset_id,
            assignees: bounty.assignees,
            bounty_type: bounty.bounty_type,
            github_issue: bounty.github_issue,
            github_pull_request: bounty.github_pull_request,
            amount: bounty.amount,
            dispute_window: bounty.dispute_window,
            tier: bounty.tier,
        };
        storage.bounties.set(index, updated);
    }
    
    #[storage(read, write)]    
    fn deposit_bounty(index: u64){
        assert(msg_amount() > 0);
        let bounty = storage.bounties.get(index).unwrap();
        assert(msg_asset_id() == bounty.asset_id);
        let updated = Bounty {
            status: bounty.status,
            issuer: bounty.issuer,
            assignees: bounty.assignees,
            asset_id: bounty.asset_id,
            bounty_type: bounty.bounty_type,
            github_issue: bounty.github_issue,
            github_pull_request: bounty.github_pull_request,
            amount: bounty.amount + msg_amount(),
            dispute_window: bounty.dispute_window, 
            tier: bounty.tier,
        };
        storage.bounties.set(index, updated);
    }
    #[storage(read, write)]    
    fn claim_bounty(index: u64) {
        let bounty: Bounty = storage.bounties.get(index).unwrap();
        match bounty.status {
            Status::completed => (),
            _ => revert(0),
        }       
        assert(timestamp() >= bounty.dispute_window);
        let updated = Bounty {
            status: Status::completed,
            issuer: bounty.issuer,
            assignees: bounty.assignees,
            asset_id: bounty.asset_id,
            bounty_type: bounty.bounty_type,
            github_issue: bounty.github_issue,
            github_pull_request: bounty.github_pull_request,
            amount: 0,
            dispute_window: bounty.dispute_window,
            tier: bounty.tier,
        };
        storage.bounties.set(index, updated);
        let mut i = 0;
        let mut y = 0;
        let mut len = 0;
        while y <= 4{
            let to: Identity = bounty.assignees.unwrap()[i];
    
            match to {
                Identity::ContractId(x) => {
                   len += 1;
                },
                Identity::Address(x) => {
                    len += 1;
                }
            }
            y += 1;
        }
        let payout = bounty.amount / 4;
        while i <= len{
            let to: Identity = bounty.assignees.unwrap()[i];
            match to{
                Identity::ContractId(x) => force_transfer_to_contract(payout, bounty.asset_id, x),
                Identity::Address(x) => transfer_to_address(payout, bounty.asset_id, x),
            }
            i += 1;
        }
    }

    #[storage(read, write)]    
    fn dispute_bounty(index: u64){
        let bounty = storage.bounties.get(index).unwrap();
        assert(msg_sender().unwrap() == bounty.issuer);
        assert(timestamp() <= bounty.dispute_window);
        match bounty.status {
            Status::completed => (),
            _ => revert(0),
        }        
        log(QueryOracle{bounty});           
    }

    #[storage(read, write)]    
    fn withdraw_bounty(index: u64){
        let bounty = storage.bounties.get(index).unwrap();
        // ensure the issuer of the bounty is the only one who can call this function
        assert(msg_sender().unwrap() == bounty.issuer);
        match bounty.status {
            Status::completed => (),
            _ => revert(0),
        }
        let updated = Bounty {
            status: Status::completed,
            issuer: bounty.issuer,
            assignees: bounty.assignees,
            asset_id: bounty.asset_id,
            bounty_type: bounty.bounty_type,
            github_issue: bounty.github_issue,
            github_pull_request: bounty.github_pull_request,
            amount: 0,
            dispute_window: bounty.dispute_window, 
            tier: bounty.tier,
        };
        storage.bounties.set(index, updated);
            match bounty.issuer{
                Identity::ContractId(x) => force_transfer_to_contract(bounty.amount, bounty.asset_id, x),
                Identity::Address(x) => transfer_to_address(bounty.amount, bounty.asset_id, x),
        }        
    }
    #[storage(read)]
    fn get_bounties() {
        let mut i: u64 = 0;
        while i > storage.bounties.len() {
            log(storage.bounties.get(i).unwrap());
        }
        i+=1;
    }
}
