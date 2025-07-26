;; Assignment Tracker - Students Submit, Teachers Verify

;; Error constants
(define-constant err-not-owner (err u100))
(define-constant err-assignment-not-found (err u101))
(define-constant err-title-too-long (err u102))
(define-constant err-description-too-long (err u103))

;; Contract owner (set on deploy)
(define-constant contract-owner tx-sender)

;; Define assignment storage
(define-map assignments
  uint
  {
    title: (string-ascii 50),
    description: (string-ascii 100),
    verified: bool,
    submitted-by: (optional principal)
  }
)

;; Assignment ID auto-increment
(define-data-var next-id uint u1)

;; Function 1: Student submits an assignment
(define-public (submit-assignment (title (string-ascii 50)) (description (string-ascii 100)))
  (begin
    ;; Validate lengths to prevent warnings
    (asserts! (<= (len title) u50) err-title-too-long)
    (asserts! (<= (len description) u100) err-description-too-long)

    (let ((id (var-get next-id)))
      (begin
        (map-set assignments id {
          title: title,
          description: description,
          verified: false,
          submitted-by: (some tx-sender)
        })
        (var-set next-id (+ id u1))
        (ok id)
      )
    )
  )
)

;; Function 2: Teacher verifies an assignment
(define-public (verify-assignment (id uint))
  (begin
    ;; Only the contract owner (teacher) can verify
    (asserts! (is-eq tx-sender contract-owner) err-not-owner)

    ;; Check if assignment exists
    (let ((maybe-assignment (map-get? assignments id)))
      (if (is-none maybe-assignment)
          err-assignment-not-found
          (let ((assignment (unwrap-panic maybe-assignment)))
            (map-set assignments id {
              title: (get title assignment),
              description: (get description assignment),
              verified: true,
              submitted-by: (get submitted-by assignment)
            })
            (ok true)
          )
      )
    )
  )
)

;; Function 3: Read an assignment by ID
(define-read-only (get-assignment (id uint))
  (match (map-get? assignments id)
    assignment (ok assignment)
    err-assignment-not-found
  )
)