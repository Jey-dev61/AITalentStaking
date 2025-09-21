;; AITalentStaking - Reputation-based staking for AI developers
;; Developers stake tokens on their expertise, earn reputation through successful projects

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-STAKE (err u101))
(define-constant ERR-PROFILE-NOT-FOUND (err u102))
(define-constant ERR-INVALID-DOMAIN (err u103))
(define-constant ERR-PROJECT-NOT-FOUND (err u104))
(define-constant ERR-INSUFFICIENT-FUNDS (err u105))
(define-constant ERR-DISPUTE-EXISTS (err u106))
(define-constant ERR-INVALID-RATING (err u107))
(define-constant ERR-ALREADY-RATED (err u108))
(define-constant ERR-INVALID-TIMEFRAME (err u109))
(define-constant ERR-WITHDRAWAL-LOCKED (err u110))

(define-data-var project-count uint u0)
(define-data-var dispute-count uint u0)
(define-data-var total-platform-fees uint u0)
(define-data-var platform-fee-rate uint u25) ;; 2.5% fee

(define-map developer-profiles
  { developer: principal }
  {
    total-stake: uint,
    reputation-score: uint,
    completed-projects: uint,
    active-since: uint,
    average-rating: uint,
    total-ratings: uint,
    locked-stake: uint,
    withdrawal-time: uint
  }
)

(define-map domain-stakes
  { developer: principal, domain: (string-ascii 50) }
  { stake-amount: uint, reputation: uint, projects-completed: uint }
)

(define-map projects
  { project-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    domain: (string-ascii 50),
    client: principal,
    developer: principal,
    stake-required: uint,
    reward: uint,
    deadline: uint,
    completed: bool,
    approved: bool,
    created-at: uint,
    rating: uint
  }
)

(define-map valid-domains
  { domain: (string-ascii 50) }
  { active: bool, min-stake: uint, project-count: uint }
)

(define-map disputes
  { dispute-id: uint }
  {
    project-id: uint,
    client: principal,
    developer: principal,
    reason: (string-ascii 200),
    resolved: bool,
    resolution: (string-ascii 200),
    created-at: uint
  }
)

(define-map milestones
  { project-id: uint, milestone-id: uint }
  {
    description: (string-ascii 200),
    reward-percentage: uint,
    completed: bool,
    approved: bool
  }
)

;; Initialize with valid AI domains
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set valid-domains { domain: "machine-learning" } { active: true, min-stake: u1000, project-count: u0 })
    (map-set valid-domains { domain: "computer-vision" } { active: true, min-stake: u1500, project-count: u0 })
    (map-set valid-domains { domain: "natural-language" } { active: true, min-stake: u1200, project-count: u0 })
    (map-set valid-domains { domain: "deep-learning" } { active: true, min-stake: u2000, project-count: u0 })
    (map-set valid-domains { domain: "data-science" } { active: true, min-stake: u800, project-count: u0 })
    (map-set valid-domains { domain: "robotics" } { active: true, min-stake: u2500, project-count: u0 })
    (map-set valid-domains { domain: "blockchain-ai" } { active: true, min-stake: u1800, project-count: u0 })
    (ok true)
  )
)

(define-public (add-domain (domain (string-ascii 50)) (min-stake uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set valid-domains 
      { domain: domain } 
      { active: true, min-stake: min-stake, project-count: u0 })
    (ok true)
  )
)

(define-public (deactivate-domain (domain (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (let
      ((domain-info (unwrap! (map-get? valid-domains { domain: domain }) ERR-INVALID-DOMAIN)))
      (map-set valid-domains 
        { domain: domain } 
        (merge domain-info { active: false }))
      (ok true)
    )
  )
)

(define-public (update-platform-fee (new-fee-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-fee-rate u100) ERR-NOT-AUTHORIZED) ;; Max 10% fee
    (var-set platform-fee-rate new-fee-rate)
    (ok true)
  )
)

;; Create or update developer profile
(define-public (create-profile)
  (let
    (
      (existing-profile (map-get? developer-profiles { developer: tx-sender }))
    )
    (if (is-some existing-profile)
      (ok false)
      (begin
        (map-set developer-profiles
          { developer: tx-sender }
          {
            total-stake: u0,
            reputation-score: u100,
            completed-projects: u0,
            active-since: block-height,
            average-rating: u0,
            total-ratings: u0,
            locked-stake: u0,
            withdrawal-time: u0
          }
        )
        (ok true)
      )
    )
  )
)

;; Stake tokens on expertise in a domain
(define-public (stake-on-domain (domain (string-ascii 50)) (amount uint))
  (let
    (
      (profile (unwrap! (map-get? developer-profiles { developer: tx-sender }) ERR-PROFILE-NOT-FOUND))
      (domain-info (unwrap! (map-get? valid-domains { domain: domain }) ERR-INVALID-DOMAIN))
      (existing-stake (default-to { stake-amount: u0, reputation: u0, projects-completed: u0 } 
                        (map-get? domain-stakes { developer: tx-sender, domain: domain })))
    )
    (asserts! (get active domain-info) ERR-INVALID-DOMAIN)
    (asserts! (>= amount (get min-stake domain-info)) ERR-INSUFFICIENT-STAKE)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set domain-stakes
      { developer: tx-sender, domain: domain }
      {
        stake-amount: (+ (get stake-amount existing-stake) amount),
        reputation: (get reputation existing-stake),
        projects-completed: (get projects-completed existing-stake)
      }
    )
    
    (map-set developer-profiles
      { developer: tx-sender }
      (merge profile { total-stake: (+ (get total-stake profile) amount) })
    )
    
    (ok true)
  )
)

;; Request stake withdrawal (with timelock)
(define-public (request-withdrawal (domain (string-ascii 50)) (amount uint))
  (let
    (
      (profile (unwrap! (map-get? developer-profiles { developer: tx-sender }) ERR-PROFILE-NOT-FOUND))
      (domain-stake (unwrap! (map-get? domain-stakes { developer: tx-sender, domain: domain }) ERR-INVALID-DOMAIN))
    )
    (asserts! (>= (get stake-amount domain-stake) amount) ERR-INSUFFICIENT-STAKE)
    (asserts! (>= (- (get total-stake profile) (get locked-stake profile)) amount) ERR-WITHDRAWAL-LOCKED)
    
    (map-set developer-profiles
      { developer: tx-sender }
      (merge profile { withdrawal-time: (+ block-height u144) }) ;; 1 day timelock
    )
    
    (ok true)
  )
)

;; Execute withdrawal after timelock
(define-public (execute-withdrawal (domain (string-ascii 50)) (amount uint))
  (let
    (
      (profile (unwrap! (map-get? developer-profiles { developer: tx-sender }) ERR-PROFILE-NOT-FOUND))
      (domain-stake (unwrap! (map-get? domain-stakes { developer: tx-sender, domain: domain }) ERR-INVALID-DOMAIN))
    )
    (asserts! (>= block-height (get withdrawal-time profile)) ERR-WITHDRAWAL-LOCKED)
    (asserts! (>= (get stake-amount domain-stake) amount) ERR-INSUFFICIENT-STAKE)
    
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    
    (map-set domain-stakes
      { developer: tx-sender, domain: domain }
      (merge domain-stake { stake-amount: (- (get stake-amount domain-stake) amount) })
    )
    
    (map-set developer-profiles
      { developer: tx-sender }
      (merge profile { 
        total-stake: (- (get total-stake profile) amount),
        withdrawal-time: u0
      })
    )
    
    (ok true)
  )
)

;; Create or update developer profile
(define-public (create-profile)
  (let
    (
      (existing-profile (map-get? developer-profiles { developer: tx-sender }))
    )
    (if (is-some existing-profile)
      (ok false)
      (begin
        (map-set developer-profiles
          { developer: tx-sender }
          {
            total-stake: u0,
            reputation-score: u100,
            completed-projects: u0,
            active-since: block-height,
            average-rating: u0,
            total-ratings: u0,
            locked-stake: u0,
            withdrawal-time: u0
          }
        )
        (ok true)
      )
    )
  )
)

;; Stake tokens on expertise in a domain
(define-public (stake-on-domain (domain (string-ascii 50)) (amount uint))
  (let
    (
      (profile (unwrap! (map-get? developer-profiles { developer: tx-sender }) ERR-PROFILE-NOT-FOUND))
      (domain-info (unwrap! (map-get? valid-domains { domain: domain }) ERR-INVALID-DOMAIN))
      (existing-stake (default-to { stake-amount: u0, reputation: u0, projects-completed: u0 } 
                        (map-get? domain-stakes { developer: tx-sender, domain: domain })))
    )
    (asserts! (get active domain-info) ERR-INVALID-DOMAIN)
    (asserts! (>= amount (get min-stake domain-info)) ERR-INSUFFICIENT-STAKE)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set domain-stakes
      { developer: tx-sender, domain: domain }
      {
        stake-amount: (+ (get stake-amount existing-stake) amount),
        reputation: (get reputation existing-stake),
        projects-completed: (get projects-completed existing-stake)
      }
    )
    
    (map-set developer-profiles
      { developer: tx-sender }
      (merge profile { total-stake: (+ (get total-stake profile) amount) })
    )
    
    (ok true)
  )
)

;; Request stake withdrawal (with timelock)
(define-public (request-withdrawal (domain (string-ascii 50)) (amount uint))
  (let
    (
      (profile (unwrap! (map-get? developer-profiles { developer: tx-sender }) ERR-PROFILE-NOT-FOUND))
      (domain-stake (unwrap! (map-get? domain-stakes { developer: tx-sender, domain: domain }) ERR-INVALID-DOMAIN))
    )
    (asserts! (>= (get stake-amount domain-stake) amount) ERR-INSUFFICIENT-STAKE)
    (asserts! (>= (- (get total-stake profile) (get locked-stake profile)) amount) ERR-WITHDRAWAL-LOCKED)
    
    (map-set developer-profiles
      { developer: tx-sender }
      (merge profile { withdrawal-time: (+ block-height u144) }) ;; 1 day timelock
    )
    
    (ok true)
  )
)

;; Execute withdrawal after timelock
(define-public (execute-withdrawal (domain (string-ascii 50)) (amount uint))
  (let
    (
      (profile (unwrap! (map-get? developer-profiles { developer: tx-sender }) ERR-PROFILE-NOT-FOUND))
      (domain-stake (unwrap! (map-get? domain-stakes { developer: tx-sender, domain: domain }) ERR-INVALID-DOMAIN))
    )
    (asserts! (>= block-height (get withdrawal-time profile)) ERR-WITHDRAWAL-LOCKED)
    (asserts! (>= (get stake-amount domain-stake) amount) ERR-INSUFFICIENT-STAKE)
    
    (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
    
    (map-set domain-stakes
      { developer: tx-sender, domain: domain }
      (merge domain-stake { stake-amount: (- (get stake-amount domain-stake) amount) })
    )
    
    (map-set developer-profiles
      { developer: tx-sender }
      (merge profile { 
        total-stake: (- (get total-stake profile) amount),
        withdrawal-time: u0
      })
    )
    
    (ok true)
  )
)