library data_structures; 

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
        //add time frame to bounty assignment for bounty reset 
        completed: bool,
    }
    pub enum Bounties{
        open: (),
        closed: (),
    }

