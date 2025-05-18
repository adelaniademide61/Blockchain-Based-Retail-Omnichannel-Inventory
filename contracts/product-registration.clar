;; Product Registration Contract
;; Records merchandise details on the blockchain

(define-data-var admin principal tx-sender)

;; Product data structure
(define-map products
  { product-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    sku: (string-utf8 50),
    category: (string-utf8 50),
    created-at: uint,
    created-by: principal
  }
)

;; Product counter
(define-data-var product-counter uint u0)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register a new product
(define-public (register-product
    (name (string-utf8 100))
    (description (string-utf8 500))
    (sku (string-utf8 50))
    (category (string-utf8 50)))
  (let
    (
      (product-id (+ (var-get product-counter) u1))
    )
    (asserts! (is-admin) (err u403))
    (map-set products
      { product-id: product-id }
      {
        name: name,
        description: description,
        sku: sku,
        category: category,
        created-at: block-height,
        created-by: tx-sender
      }
    )
    (var-set product-counter product-id)
    (ok product-id)
  )
)

;; Update product details
(define-public (update-product
    (product-id uint)
    (name (string-utf8 100))
    (description (string-utf8 500))
    (category (string-utf8 50)))
  (let
    (
      (product (unwrap! (map-get? products { product-id: product-id }) (err u404)))
    )
    (asserts! (is-admin) (err u403))
    (map-set products
      { product-id: product-id }
      (merge product {
        name: name,
        description: description,
        category: category
      })
    )
    (ok true)
  )
)

;; Get product details
(define-read-only (get-product (product-id uint))
  (map-get? products { product-id: product-id })
)

;; Check if product exists
(define-read-only (product-exists (product-id uint))
  (is-some (map-get? products { product-id: product-id }))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
