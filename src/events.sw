library events;

dep data_structures;
use data_structures::*;

pub struct BountySubmitted{
    bounty: Bounty,
}

pub struct QueryOracle{
    users: [Identity; 4],
}

pub struct CheckStatus{
    bounty: Bounty,
}