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
        assignees: Option<[Identity; 4]>,
        bounty_type: Bounties,
        github_issue: str[64],
        github_pull_request: Option<str[64]>,
        amount: u64,
        dispute_window: u64, 
    }
    pub enum Bounties{
        open: (),
        closed: (),
    }
