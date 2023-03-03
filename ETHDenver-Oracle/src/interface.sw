library interface;

dep data_structures;
dep events;
use events::*;
use data_structures::*;

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