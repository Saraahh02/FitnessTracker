# FitnessTracker

A blockchain-based personal fitness and workout tracking system. Log your workouts, track progress, and maintain a permanent record of your fitness journey on the Stacks blockchain.

## Features

- **Workout Logging**: Record detailed workout sessions with descriptions
- **Exercise Categories**: Track different types of exercises (Cardio, Strength, Flexibility, Sports, Yoga, CrossFit)
- **Intensity Tracking**: Monitor workout intensity from Light to Extreme
- **Duration Monitoring**: Track workout duration for better time management
- **Immutable Records**: All fitness data stored permanently on blockchain

## Smart Contract Functions

### Public Functions
- `log-workout`: Record a completed workout session
- `cancel-workout`: Mark a workout as cancelled

### Read-Only Functions
- `get-workout`: Retrieve workout details by ID
- `get-athlete`: Get the athlete who logged a specific workout

## Getting Started

1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify contract validity
4. Deploy to Stacks testnet or mainnet

## License

MIT License
\`\`\`

```clarity file="project-3-bookclub/contracts/book-club.clar"
;; BookClub: Decentralized Book Review and Recommendation Platform
;; Version: 1.0.0

(define-constant ERR-PERMISSION-DENIED (err u1))
(define-constant ERR-REVIEW-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-PUBLISHED (err u3))
(define-constant ERR-INVALID-STATE (err u4))
(define-constant ERR-INVALID-PAGE-COUNT (err u5))
(define-constant ERR-INVALID-GENRE (err u6))
(define-constant ERR-INVALID-RATING (err u7))
(define-constant ERR-INVALID-BOOK-TITLE (err u8))
(define-constant ERR-INVALID-REVIEW-TEXT (err u9))

(define-constant MIN-PAGE-COUNT u50)

(define-data-var next-review-id uint u1)

(define-map book-reviews
    uint
    {
        reviewer: principal,
        book-title: (string-utf8 50),
        review-text: (string-utf8 200),
        genre: (string-utf8 15),
        rating: (string-utf8 10),
        visibility-status: (string-utf8 15),
        page-count: uint
    }
)

(define-private (validate-genre (genre (string-utf8 15)))
    (or 
        (is-eq genre u"Fiction")
        (is-eq genre u"NonFiction")
        (is-eq genre u"Mystery")
        (is-eq genre u"Romance")
        (is-eq genre u"SciFi")
        (is-eq genre u"Biography")
    )
)

(define-private (validate-rating (rating (string-utf8 10)))
    (or 
        (is-eq rating u"OneStar")
        (is-eq rating u"TwoStar")
        (is-eq rating u"ThreeStar")
        (is-eq rating u"FourStar")
        (is-eq rating u"FiveStar")
    )
)

(define-private (validate-text-length (text (string-utf8 200)) (min-length uint) (max-length uint))
    (let 
        (
            (text-length (len text))
        )
        (and 
            (>= text-length min-length)
            (<= text-length max-length)
        )
    )
)

(define-public (submit-review 
    (book-title (string-utf8 50))
    (review-text (string-utf8 200))
    (genre (string-utf8 15))
    (rating (string-utf8 10))
    (page-count uint)
)
    (let
        (
            (review-id (var-get next-review-id))
        )
        (asserts! (validate-text-length book-title u3 u50) ERR-INVALID-BOOK-TITLE)
        (asserts! (validate-text-length review-text u10 u200) ERR-INVALID-REVIEW-TEXT)
        (asserts! (>= page-count MIN-PAGE-COUNT) ERR-INVALID-PAGE-COUNT)
        (asserts! (validate-genre genre) ERR-INVALID-GENRE)
        (asserts! (validate-rating rating) ERR-INVALID-RATING)
        
        (map-set book-reviews review-id {
            reviewer: tx-sender,
            book-title: book-title,
            review-text: review-text,
            genre: genre,
            rating: rating,
            visibility-status: u"public",
            page-count: page-count
        })
        (var-set next-review-id (+ review-id u1))
        (ok review-id)
    )
)

(define-public (hide-review (review-id uint))
    (let
        (
            (review (unwrap! (map-get? book-reviews review-id) ERR-REVIEW-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get reviewer review)) ERR-PERMISSION-DENIED)
        (asserts! (is-eq (get visibility-status review) u"public") ERR-INVALID-STATE)
        (ok (map-set book-reviews review-id (merge review { visibility-status: u"hidden" })))
    )
)

(define-read-only (get-review (review-id uint))
    (ok (map-get? book-reviews review-id))
)

(define-read-only (get-reviewer (review-id uint))
    (ok (get reviewer (unwrap! (map-get? book-reviews review-id) ERR-REVIEW-NOT-FOUND)))
)
