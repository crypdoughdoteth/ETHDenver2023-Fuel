library data_structures; 

    pub enum Status{
        available: (),
        in_progress: (),
        completed: (),
    }

    pub struct Bounty {
        status: Status,
        issuer: Identity,
        asset_id: ContractId,
        assignees: Option<Address>,
        bounty_type: Bounties,
        github_issue: str[64],
        github_pull_request: Option<str[64]>,
        amount: u64,
        tier: Tier,
    }
    pub enum Bounties{
        open: (),
        closed: (),
    }

    pub enum Tier{
        gold: (),
        silver: (),
        bronze: (),
        default: (),
    }
