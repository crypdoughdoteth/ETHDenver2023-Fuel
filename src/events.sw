library events;

dep data_structures;
use data_structures::*;

    pub struct BountyAssigned{
        users: Address,
    }
    pub struct QueryOracle{
        bounty: Bounty,
    }
    pub struct BountyCreated{
        bounty: Bounty,
    }
