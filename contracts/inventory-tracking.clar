;; Inventory Tracking Contract
;; Monitors stock levels across retail locations

(define-data-var admin principal tx-sender)

;; Inventory data structure
(define-map inventory
  { store-id: uint, product-id: uint }
  {
    quantity: uint,
    last-updated: uint
  }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Update inventory
(define-public (update-inventory (store-id uint) (product-id uint) (quantity uint))
  (begin
    (asserts! (is-admin) (err u403))
    (map-set inventory
      { store-id: store-id, product-id: product-id }
      {
        quantity: quantity,
        last-updated: block-height
      }
    )
    (ok true)
  )
)

;; Add to inventory
(define-public (add-to-inventory (store-id uint) (product-id uint) (quantity uint))
  (let
    (
      (current-inventory (default-to { quantity: u0, last-updated: u0 }
                          (map-get? inventory { store-id: store-id, product-id: product-id })))
      (new-quantity (+ (get quantity current-inventory) quantity))
    )
    (asserts! (is-admin) (err u403))
    (map-set inventory
      { store-id: store-id, product-id: product-id }
      {
        quantity: new-quantity,
        last-updated: block-height
      }
    )
    (ok new-quantity)
  )
)

;; Remove from inventory
(define-public (remove-from-inventory (store-id uint) (product-id uint) (quantity uint))
  (let
    (
      (current-inventory (default-to { quantity: u0, last-updated: u0 }
                          (map-get? inventory { store-id: store-id, product-id: product-id })))
      (current-quantity (get quantity current-inventory))
    )
    (asserts! (is-admin) (err u403))
    (asserts! (>= current-quantity quantity) (err u400))
    (map-set inventory
      { store-id: store-id, product-id: product-id }
      {
        quantity: (- current-quantity quantity),
        last-updated: block-height
      }
    )
    (ok (- current-quantity quantity))
  )
)

;; Get inventory level
(define-read-only (get-inventory (store-id uint) (product-id uint))
  (default-to { quantity: u0, last-updated: u0 }
            (map-get? inventory { store-id: store-id, product-id: product-id }))
)

;; Check if product is in stock
(define-read-only (is-in-stock (store-id uint) (product-id uint) (required-quantity uint))
  (let
    (
      (current-inventory (get-inventory store-id product-id))
      (current-quantity (get quantity current-inventory))
    )
    (>= current-quantity required-quantity)
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
