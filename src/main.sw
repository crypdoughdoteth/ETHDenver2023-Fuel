contract;

use std::storage::{StorageVec, StorageMap};
use std::revert::revert;
use std::auth::msg_sender;
use std::logging::log;

//Events
    pub struct BountyAssigned{
        users: [Identity;4],
    }
    pub struct QueryOracle{
        bounty: Bounty,
    }
    pub struct BountyCreated{
        bounty: Bounty,
    }
//Types
    pub enum Status{
        available: (),
        in_progress: (),
        completed: (),
    }

    pub struct Bounty {
        status: Status,
        issuer: Identity,
        assignees: Option<[Identity; 4]>,
        bounty_type: Bounties,
        github_issue: str[64],
        github_pull_request: Option<str[64]>,
        completed: bool,
    }
    pub enum Bounties{
        open: (),
        closed: (),
    }
abi BountyBoard {
    #[storage(read, write)]
    fn new(type_of: Bounties, issue: str[64]);
    #[storage(read, write)]
    fn attempt_bounty(index: u64, bounty_hunters: [Identity;4], pr: str[64]);
    #[storage(read, write)]
    fn assign_bounty(index: u64, bounty_hunters: [Identity;4], pr: str[64]);
    #[storage(read, write)]
    fn settle_bounty(index: u64);
    #[storage(read, write)]
    fn unlock_bounty(index: u64);
}

const ORACLE_CONTRACT: Identity = Identity::ContractId(ContractId::from(0x79fa8779bed2f36c3581d01c79df8da45eee09fac1fd76a5a656e16326317ef0));

storage {
    //hard code oracle or change from constructor 
    #[storage(read, write)]
    bounties: StorageVec<Bounty> = StorageVec{},
}
impl BountyBoard for Contract {
 #[storage(read, write)]
    fn new(type_of: Bounties, issue: str[64]){
       let bty = Bounty{
            status: Status::available,
            issuer: msg_sender().unwrap(),
            assignees: Option::None,
            bounty_type: type_of,
            github_issue: issue,
            github_pull_request: Option::None,
            completed: false,
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
            assignees: Option::Some(bounty_hunters),
            bounty_type: bounty.bounty_type,
            github_issue: bounty.github_issue,
            github_pull_request: Option::Some(pr),
            completed: bounty.completed,
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
            assignees: Option::Some(bounty_hunters),
            bounty_type: bounty.bounty_type,
            github_issue: bounty.github_issue,
            github_pull_request: Option::Some(pr),
            completed: bounty.completed,
        };
        storage.bounties.set(index, update_bounty);
        //  emit event
        log(BountyAssigned{users: bounty_hunters});
    }
    #[storage(read, write)]
    fn settle_bounty(index: u64) {
        //only callable if assigned to a bounty
        // emit event that the Oracle tracks: make API call to github -> write to this contract again + unlock predicate
        let bounty = storage.bounties.get(index).unwrap();
        assert(bounty.completed == false);
        log(QueryOracle{bounty});        
        //emit event
    }
    #[storage(read, write)]
    fn unlock_bounty(index: u64) {
        //this will be called by the oracle only, guard fn accordingly with assert
        //only call if state change => true 
        //oracle will call the github API to check state of the pull request. If PR is merged => set completed in the struct to true
        let sender = msg_sender().unwrap();

        assert(sender == ORACLE_CONTRACT);

        let bounty = storage.bounties.get(index).unwrap();
        let updated = Bounty {
            status: Status::completed,
            issuer: bounty.issuer,
            assignees: bounty.assignees,
            bounty_type: bounty.bounty_type,
            github_issue: bounty.github_issue,
            github_pull_request: bounty.github_pull_request,
            completed: true,
        };
        storage.bounties.set(index, updated);
    }

}
