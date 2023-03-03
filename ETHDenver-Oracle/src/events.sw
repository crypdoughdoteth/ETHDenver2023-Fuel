library events;

dep data_structures;
use data_structures::*;

    pub struct BountyAssigned{
        users: [Identity;4],
    }
    pub struct QueryOracle{
        bounty: Bounty,
    }
    pub struct BountyCreated{
        bounty: Bounty,
    }