;; FitnessTracker: Personal Workout and Fitness Goal Management System
;; Version: 1.0.0

(define-constant ERR-ACCESS-DENIED (err u1))
(define-constant ERR-WORKOUT-NOT-FOUND (err u2))
(define-constant ERR-ALREADY-COMPLETED (err u3))
(define-constant ERR-INVALID-STATUS (err u4))
(define-constant ERR-INVALID-DURATION (err u5))
(define-constant ERR-INVALID-EXERCISE-TYPE (err u6))
(define-constant ERR-INVALID-INTENSITY-LEVEL (err u7))
(define-constant ERR-INVALID-WORKOUT-NAME (err u8))
(define-constant ERR-INVALID-DESCRIPTION (err u9))

(define-constant MIN-WORKOUT-DURATION u15)

(define-data-var next-workout-id uint u1)

(define-map fitness-sessions
    uint
    {
        athlete: principal,
        workout-name: (string-utf8 50),
        description: (string-utf8 200),
        exercise-type: (string-utf8 15),
        intensity-level: (string-utf8 10),
        completion-status: (string-utf8 15),
        duration-minutes: uint
    }
)

(define-private (validate-exercise-type (exercise-type (string-utf8 15)))
    (or 
        (is-eq exercise-type u"Cardio")
        (is-eq exercise-type u"Strength")
        (is-eq exercise-type u"Flexibility")
        (is-eq exercise-type u"Sports")
        (is-eq exercise-type u"Yoga")
        (is-eq exercise-type u"CrossFit")
    )
)

(define-private (validate-intensity-level (intensity-level (string-utf8 10)))
    (or 
        (is-eq intensity-level u"Light")
        (is-eq intensity-level u"Moderate")
        (is-eq intensity-level u"Vigorous")
        (is-eq intensity-level u"High")
        (is-eq intensity-level u"Extreme")
    )
)

(define-private (validate-text-input (text (string-utf8 200)) (min-length uint) (max-length uint))
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

(define-public (log-workout 
    (workout-name (string-utf8 50))
    (description (string-utf8 200))
    (exercise-type (string-utf8 15))
    (intensity-level (string-utf8 10))
    (duration-minutes uint)
)
    (let
        (
            (workout-id (var-get next-workout-id))
        )
        (asserts! (validate-text-input workout-name u3 u50) ERR-INVALID-WORKOUT-NAME)
        (asserts! (validate-text-input description u10 u200) ERR-INVALID-DESCRIPTION)
        (asserts! (>= duration-minutes MIN-WORKOUT-DURATION) ERR-INVALID-DURATION)
        (asserts! (validate-exercise-type exercise-type) ERR-INVALID-EXERCISE-TYPE)
        (asserts! (validate-intensity-level intensity-level) ERR-INVALID-INTENSITY-LEVEL)
        
        (map-set fitness-sessions workout-id {
            athlete: tx-sender,
            workout-name: workout-name,
            description: description,
            exercise-type: exercise-type,
            intensity-level: intensity-level,
            completion-status: u"completed",
            duration-minutes: duration-minutes
        })
        (var-set next-workout-id (+ workout-id u1))
        (ok workout-id)
    )
)

(define-public (cancel-workout (workout-id uint))
    (let
        (
            (workout (unwrap! (map-get? fitness-sessions workout-id) ERR-WORKOUT-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (get athlete workout)) ERR-ACCESS-DENIED)
        (asserts! (is-eq (get completion-status workout) u"completed") ERR-INVALID-STATUS)
        (ok (map-set fitness-sessions workout-id (merge workout { completion-status: u"cancelled" })))
    )
)

(define-read-only (get-workout (workout-id uint))
    (ok (map-get? fitness-sessions workout-id))
)

(define-read-only (get-athlete (workout-id uint))
    (ok (get athlete (unwrap! (map-get? fitness-sessions workout-id) ERR-WORKOUT-NOT-FOUND)))
)
