-- Three-way match: Purchase Order -> Invoice -> Payment
-- Flags exceptions for AP review

WITH matched AS (
    SELECT
        i.invoice_id,
        i.supplier,
        i.po_id,
        po.po_amount,
        i.invoice_amount,
        COALESCE(SUM(p.payment_amount), 0) AS total_paid
    FROM invoices i
    LEFT JOIN purchase_orders po ON po.po_id = i.po_id
    LEFT JOIN payments p ON p.invoice_id = i.invoice_id
    GROUP BY i.invoice_id
)
SELECT
    invoice_id,
    supplier,
    po_id,
    po_amount,
    invoice_amount,
    total_paid,
    CASE
        WHEN po_amount IS NULL THEN 'No matching PO'
        WHEN ABS(invoice_amount - po_amount) > 0.01 THEN 'PO/Invoice amount mismatch'
        WHEN total_paid = 0 THEN 'Unpaid'
        WHEN ABS(total_paid - invoice_amount) > 0.01 THEN 'Payment amount mismatch'
        ELSE 'OK'
    END AS exception_type
FROM matched
ORDER BY exception_type, invoice_id;
