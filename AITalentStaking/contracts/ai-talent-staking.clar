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