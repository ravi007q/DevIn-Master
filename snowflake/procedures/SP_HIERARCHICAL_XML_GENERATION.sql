-- ============================================================================
-- Procedure : SP_HIERARCHICAL_XML_GENERATION
-- Source map: m_hierarchical_xml_generation (Sample_5_Mapping.xml)
-- Pattern   : Full Refresh (Hierarchical XML Construction)
--
-- Transformation pipeline mapped to SQL:
--   JNR_Orders_Items   -> INNER JOIN ORDERS o / ORDER_ITEMS i ON o.ORDER_ID = i.ORDER_ID
--   XMLG_Order_Payload -> XPK (parent key)  => GROUP BY ORDER_ID
--                         XFK (child key)   => LISTAGG nested <Item> elements
--                         element building  => string concatenation of XML tags
--
-- Output XML (BR section 6.6): one <Order> per ORDER_ID with nested <Items>.
-- BR-1/BR-6: only orders with >= 1 line item (INNER JOIN).
-- BR-2: items ordered by ITEM_ID. BR-4: NULL SKU -> empty <SKU></SKU>.
-- BR-5: ORDER_DATE in ISO 8601.
-- ============================================================================
CREATE OR REPLACE PROCEDURE SP_HIERARCHICAL_XML_GENERATION()
RETURNS STRING
LANGUAGE SQL
AS
$$
DECLARE
    rows_loaded INTEGER DEFAULT 0;
BEGIN
    TRUNCATE TABLE ORDER_XML_PAYLOADS;

    INSERT INTO ORDER_XML_PAYLOADS
        (ORDER_ID, CUSTOMER_ID, ORDER_DATE, XML_PAYLOAD, LOAD_TIMESTAMP)
    SELECT
        o.ORDER_ID,
        o.CUST_ID,
        o.ORDER_DATE,
        '<Order>'
            || '<OrderId>' || o.ORDER_ID || '</OrderId>'
            || '<CustomerId>' || o.CUST_ID || '</CustomerId>'
            || '<OrderDate>' || TO_CHAR(o.ORDER_DATE, 'YYYY-MM-DD"T"HH24:MI:SS') || '</OrderDate>'
            || '<Items>'
            || LISTAGG(
                   '<Item>'
                   || '<ItemNumber>' || i.ITEM_ID || '</ItemNumber>'
                   || '<SKU>' || COALESCE(i.PRODUCT_SKU, '') || '</SKU>'   -- BR-4
                   || '<Quantity>' || i.QTY || '</Quantity>'
                   || '</Item>'
               ) WITHIN GROUP (ORDER BY i.ITEM_ID)                          -- BR-2
            || '</Items>'
        || '</Order>' AS XML_PAYLOAD,
        CURRENT_TIMESTAMP()
    FROM ORDERS o
    INNER JOIN ORDER_ITEMS i                                                -- BR-1, BR-6
        ON o.ORDER_ID = i.ORDER_ID
    GROUP BY o.ORDER_ID, o.CUST_ID, o.ORDER_DATE;                           -- BR-3 (one row per order)

    rows_loaded := SQLROWCOUNT;
    RETURN 'SP_HIERARCHICAL_XML_GENERATION: generated ' || rows_loaded || ' order XML payload(s).';
END;
$$;
