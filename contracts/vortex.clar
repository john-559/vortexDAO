;; VortexDAO Governance Contract - Enhanced Version

;; Constants
(define-constant ERROR-UNAUTHORIZED (err u100))
(define-constant ERROR-MOTION-EXISTS (err u101))
(define-constant ERROR-MOTION-NOT-FOUND (err u102))
(define-constant ERROR-ALREADY-CAST (err u103))
(define-constant ERROR-MOTION-CONCLUDED (err u104))
(define-constant ERROR-INSUFFICIENT-TOKENS (err u105))
(define-constant ERROR-INVALID-HEADER (err u106))
(define-constant ERROR-INVALID-CONTENT (err u107))
(define-constant ERROR-INVALID-FUNDING (err u108))
(define-constant ERROR-INVALID-RECIPIENT (err u109))
(define-constant ERROR-MOTION-INACTIVE (err u110))
(define-constant ERROR-MOTION-ONGOING (err u111))
(define-constant ERROR-INVALID-BALLOT-AMOUNT (err u112))
(define-constant ERROR-INSUFFICIENT-BALLOT-POWER (err u113))
(define-constant ERROR-TREASURY-UNDERFUNDED (err u114))
(define-constant ERROR-MOTION-EXECUTED (err u115))
(define-constant ERROR-SELF-DELEGATION (err u116))
(define-constant ERROR-INVALID-PARTICIPATION (err u117))
(define-constant ERROR-INVALID-EXTRA_INFO (err u118))

;; Data Variables with Admin Controls
(define-data-var dao-administrator principal tx-sender)
(define-data-var min-motion-threshold uint u100000000) ;; 100 STX minimum
(define-data-var ballot-period uint u144) ;; ~24 hours in blocks
(define-data-var participation-threshold uint u500000000000) ;; 500 STX minimum total votes
(define-data-var motion-submission-active bool true)
(define-data-var ballot-casting-active bool true)
(define-data-var min-ballot-delay uint u10) ;; Minimum blocks before voting starts
(define-data-var max-ballot-delay uint u100) ;; Maximum blocks before voting starts

;; Enhanced Motion Structure
(define-map motions
    {motion-id: uint}
    {
        proposer: principal,
        header: (string-utf8 256),
        content: (string-utf8 1024),
        funding: uint,
        recipient: principal,
        start-height: uint,
        end-height: uint,
        support-ballots: uint,
        oppose-ballots: uint,
        completed: bool,
        terminated: bool,
        completion-delay: uint,
        last-modified: uint,
        extra-info: (optional (string-utf8 1024))
    }
)

;; Enhanced Voting System
(define-map ballots
    {motion-id: uint, participant: principal}
    {
        quantity: uint,
        position: bool,
        ballot-power: uint,
        cast-time: uint,
        representative: (optional principal)
    }
)

;; Enhanced Delegation System
(define-map representation-info
    {delegator: principal}
    {
        representative: principal,
        ballot-power: uint,
        last-modified: uint,
        can-reassign: bool
    }
)

;; Vote Tracking
(define-map participant-ballot-records
    principal
    {
        total-ballots: uint,
        motions-participated: (list 50 uint)  ;; Store last 50 motions voted on
    }
)

;; Storage
(define-data-var motion-counter uint u0)
(define-data-var treasury-funds uint u0)
(define-data-var total-ballot-power uint u0)

;; Governance Token
(define-fungible-token vortex-token)

;; Access Control
(define-private (is-dao-administrator)
    (is-eq tx-sender (var-get dao-administrator))
)

(define-private (is-authorized-proposer (sender principal))
    (and 
        (var-get motion-submission-active)
        (>= (ft-get-balance vortex-token sender) (var-get min-motion-threshold))
    )
)

;; Vote Tracking Functions
(define-private (get-total-ballots-cast (participant principal))
    (match (map-get? participant-ballot-records participant)
        ballot-info (get total-ballots ballot-info)
        u0
    )
)

(define-private (update-ballot-record (participant principal) (motion-id uint))
    (let (
        (current-info (default-to 
            {total-ballots: u0, motions-participated: (list)}
            (map-get? participant-ballot-records participant)
        ))
    )
        (map-set participant-ballot-records
            participant
            {
                total-ballots: (+ (get total-ballots current-info) u1),
                motions-participated: (unwrap-panic (as-max-len? 
                    (append (get motions-participated current-info) motion-id)
                    u50))
            }
        )
    )
)

;; Enhanced Read-only Functions
(define-read-only (get-motion-details (motion-id uint))
    (match (map-get? motions {motion-id: motion-id})
        motion (ok {
            motion: motion,
            participation-met: (>= (+ (get support-ballots motion) (get oppose-ballots motion)) (var-get participation-threshold)),
            ballot-difference: (- (get support-ballots motion) (get oppose-ballots motion)),
            can-complete: (and 
                (>= (+ (get support-ballots motion) (get oppose-ballots motion)) (var-get participation-threshold))
                (> (get support-ballots motion) (get oppose-ballots motion))
                (not (get completed motion))
                (not (get terminated motion))
                (>= block-height (get end-height motion))
            )
        })
        ERROR-MOTION-NOT-FOUND
    )
)

(define-read-only (get-participant-info (participant principal))
    (ok {
        ballot-power: (ft-get-balance vortex-token participant),
        representation: (map-get? representation-info {delegator: participant}),
        total-ballots-cast: (get-total-ballots-cast participant)
    })
)

;; Enhanced Helper Functions
(define-private (validate-motion-params 
    (header (string-utf8 256))
    (content (string-utf8 1024))
    (funding uint)
    (recipient principal)
)
    (and
        (is-valid-header header)
        (is-valid-content content)
        (is-valid-funding funding)
        (is-valid-recipient recipient)
        (>= (var-get treasury-funds) funding)
    )
)

(define-private (process-ballot 
    (motion-id uint)
    (participant principal)
    (quantity uint)
    (position bool)
)
    (match (map-get? motions {motion-id: motion-id})
        motion (let (
            (ballot-power (ft-get-balance vortex-token participant))
        )
            (asserts! (>= ballot-power quantity) ERROR-INSUFFICIENT-BALLOT-POWER)
            (asserts! (not (get completed motion)) ERROR-MOTION-EXECUTED)
            (asserts! (not (get terminated motion)) ERROR-MOTION-INACTIVE)
            (ok {
                ballot-power: ballot-power,
                quantity: quantity,
                position: position,
                cast-time: block-height
            }))
        ERROR-MOTION-NOT-FOUND
    )
)

;; Input Validation Functions
(define-private (is-valid-header (header (string-utf8 256)))
    (and (>= (len header) u1) (<= (len header) u256))
)

(define-private (is-valid-content (content (string-utf8 1024)))
    (and (>= (len content) u1) (<= (len content) u1024))
)

(define-private (is-valid-funding (funding uint))
    (> funding u0)
)

(define-private (is-valid-recipient (recipient principal))
    (not (is-eq recipient (as-contract tx-sender)))
)

(define-private (is-valid-extra-info (extra-info (optional (string-utf8 1024))))
    (match extra-info
        value (and (>= (len value) u1) (<= (len value) u1024))
        true
    )
)

;; Enhanced Public Functions
(define-public (create-motion (header (string-utf8 256)) 
                              (content (string-utf8 1024)) 
                              (funding uint) 
                              (recipient principal)
                              (completion-delay uint)
                              (extra-info (optional (string-utf8 1024))))
    (let (
        (motion-id (+ (var-get motion-counter) u1))
        (start-height (+ block-height (var-get min-ballot-delay)))
        (end-height (+ start-height (var-get ballot-period)))
    )
        (asserts! (is-authorized-proposer tx-sender) ERROR-UNAUTHORIZED)
        (asserts! (validate-motion-params header content funding recipient) ERROR-INVALID-FUNDING)
        (asserts! (<= completion-delay (var-get max-ballot-delay)) ERROR-INVALID-FUNDING)
        (asserts! (is-valid-extra-info extra-info) ERROR-INVALID-EXTRA_INFO)
        
        (map-set motions
            {motion-id: motion-id}
            {
                proposer: tx-sender,
                header: header,
                content: content,
                funding: funding,
                recipient: recipient,
                start-height: start-height,
                end-height: end-height,
                support-ballots: u0,
                oppose-ballots: u0,
                completed: false,
                terminated: false,
                completion-delay: completion-delay,
                last-modified: block-height,
                extra-info: extra-info
            }
        )
        (var-set motion-counter motion-id)
        (ok motion-id)
    )
)

;; Administrative Functions
(define-public (set-dao-administrator (new-administrator principal))
    (begin
        (asserts! (is-dao-administrator) ERROR-UNAUTHORIZED)
        (asserts! (is-valid-recipient new-administrator) ERROR-INVALID-RECIPIENT)
        (ok (var-set dao-administrator new-administrator))
    )
)

(define-public (update-dao-parameters
    (new-min-motion-threshold uint)
    (new-ballot-period uint)
    (new-participation-threshold uint))
    (begin
        (asserts! (is-dao-administrator) ERROR-UNAUTHORIZED)
        (asserts! (> new-participation-threshold u0) ERROR-INVALID-PARTICIPATION)
        (asserts! (> new-min-motion-threshold u0) ERROR-INVALID-FUNDING)
        (asserts! (> new-ballot-period u0) ERROR-INVALID-FUNDING)
        (var-set min-motion-threshold new-min-motion-threshold)
        (var-set ballot-period new-ballot-period)
        (var-set participation-threshold new-participation-threshold)
        (ok true)
    )
)

(define-public (toggle-motion-submission (active bool))
    (begin
        (asserts! (is-dao-administrator) ERROR-UNAUTHORIZED)
        (ok (var-set motion-submission-active active))
    )
)