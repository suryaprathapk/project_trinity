--WAC  price for a product and period

SELECT
    li.prod_num,
    li.base_price,
    li.start_date,
    li.end_date,
    doc.prc_doc_status
FROM
    mn_structured_doc     doc,
    mn_struct_line_item   li
WHERE
    doc.struct_doc_type = 'WAC'
    AND doc.struct_doc_id = li.struct_doc_id;

--Govt. Contracts - contracts of type government with start and end date

SELECT
    doc.struct_doc_id_num,
    doc.start_date,
    doc.end_date,
    ctrt.ctrt_doc_status
FROM
    mn_structured_doc        doc,
    mn_structured_contract   ctrt
WHERE
    ctrt_doc_domain = 'GOV'
    AND doc.struct_doc_id = ctrt.struct_doc_id;

--Commercial contracts - contracts of type commercial (provider) with start and end date
SELECT
    doc.struct_doc_id_num,
    doc.start_date,
    doc.end_date,
    ctrt.ctrt_doc_status
FROM
    mn_structured_doc        doc,
    mn_structured_contract   ctrt
WHERE
    ctrt_doc_domain = 'COM'
    AND doc.struct_doc_id = ctrt.struct_doc_id;

--Off Invoice Discount - Invoice discount as defined in contracts
SELECT
   *
FROM (
    SELECT
        li.prod_num as actual_prod_num, cm.product_num, cm.ndc, item.cat_map_id,
        COALESCE(fld.fld_value, fldRealmLocale.fld_value, cm.map_name) as map_name,
        pg.sect_name,
        pg.prc_method,
        pmli.eff_start_date as start_date,
        pmli.eff_end_date as end_date,
        li.pg_order_index,
        li.struct_li_id,
        pg.struct_doc_sect_id,
        /* 'null' As cf_strategy_id     hardcoded cf_strategy_id for non strategy product groups */
        pg.price_basis,
        li.cat_obj_type,
        CASE
            WHEN ( pg.category_pricing = 'PRICE' AND pmli.price IS NOT NULL)
            THEN
                (pmli.price  + nvl(pmli.up_charge,0) )

            WHEN (pg.category_pricing = 'PRICE' AND pmli.alt_uom_price is not null) THEN
                pmli.alt_uom_price * (uom.from_quantity / uom.to_quantity)

            WHEN (pg.category_pricing = 'DISCOUNT' AND pmli.product_mgr_id   = '22101')
          THEN case
              WHEN (pmli.adjust_by = '%' and price_list.price is not null)
              THEN ((price_list.price + (pmli.adjustment * price_list.price)) + nvl(pmli.up_charge,0)) *NVL(pmli.cummulative_increase_percent,1)
              when (pmli.adjust_by = '$' and price_list.price is not null)
              then ((price_list.price + pmli.adjustment) + nvl(pmli.up_charge,0)) * NVL(pmli.cummulative_increase_percent,1)
              END
          ELSE (pmli.price + nvl(pmli.up_charge,0))
        END AS price,
        pmli.pricing_method,
        pmli.adjust_by,
        pmli.adjustment,
        NVL(pmli.tier_index + 1, 1) AS rn,
        doc.effective_timezone AS timezone,
        COALESCE(pmli.price_curr, doc.currency) as currency,
        'false' AS priceCap
    FROM
        mn_structured_doc doc
        INNER JOIN mn_struct_doc_sect_ver pg ON (
            pg.struct_doc_id = doc.struct_doc_id AND
            pg.ver_num <= doc.ver_num AND
            pg.end_ver_num > doc.ver_num
        )
        INNER JOIN mn_struct_line_item_ver li ON (
            li.prod_grp_id = pg.struct_doc_sect_id AND
            li.ver_num <= pg.ver_num AND
            li.end_ver_num > pg.ver_num
        )
        INNER JOIN mn_map_edge_path_node path ON (
            li.cat_obj_id = path.node_id
        )
        INNER JOIN mn_item item ON (
             path.root_node = item.cat_map_id
        )
        INNER JOIN mn_cat_map cm ON (
            item.cat_map_id = cm.cat_map_id and
            cm.repack = 0
        )
        LEFT OUTER JOIN mn_cat_map_field fld ON (
            fld.cat_map_id = cm.cat_map_id  and
            fld.fld_name like 'name'
        )
        LEFT OUTER JOIN mn_cat_map_field fldRealmLocale ON (
            fldRealmLocale.cat_map_id = cm.cat_map_id  and
            fldRealmLocale.fld_name like 'name'
        )
       INNER JOIN mn_price_master_li pmli ON (
            pmli.struct_doc_id = doc.struct_doc_id
            AND pmli.line_item_id = li.struct_li_id
            AND mn_current_time BETWEEN pmli.model_start_date and pmli.model_end_date
            and pmli.exclusion = 0
        )
        left outer JOIN MN_PRICE_MASTER_LI price_list ON (
            price_list.struct_doc_id = pmli.price_list_id
            AND price_list.product_id = cm.cat_map_id
            AND mn_current_time between price_list.eff_start_date and price_list.eff_end_date
            AND pmli.price_list_model_date is not null
            AND pmli.price_list_model_date <= price_list.model_end_date
            and pmli.price_list_model_date >= price_list.model_start_date
        )
        LEFT OUTER JOIN mn_uom_conversion uom ON (
                 UOM.ITEM_ID = cm.cat_map_id  AND
                 pmli.eff_start_date between uom.eff_start_date AND  uom.eff_end_date
                 AND uom.from_uom = pmli.price_basis
        )


    )   WHERE start_date<= end_date;


--customer - All eligible customer for a monthly period or eligible customers with start/ end date
SELECT
  eligcust.root_src_id                  AS root_src_id,
  prog.cf_strategy_id                       AS src_id,
  prog.ver_num                      AS src_ver_num,
  eligcust.bucket_src_id             AS bucket_src_id,
  eligcust.filter_name             AS filter_name,
  eligcust.commit_id               AS commit_id,
  cmt.ver_num                      AS commit_ver_num,
  NVL(cmt.is_access_price_flag, 0) AS is_access_price_flag,
  eligcust.member_id               AS member_id,
  eligcust.start_date              AS start_date,
  eligcust.end_date                AS end_date,
  eligcust.inc_flag                AS inc_flag
FROM
  mn_cf_eligible_customer eligcust
  INNER JOIN mn_ctrt_model_dates doc ON (
      doc.struct_doc_id = eligcust.root_src_id AND
      MN_CURRENT_TIME BETWEEN doc.model_start_date AND doc.model_end_date
  )
  LEFT OUTER JOIN mn_commitment_ver cmt ON (
    cmt.commit_id = eligcust.commit_id AND
    cmt.ver_num <= doc.ctrt_ver_num AND
    cmt.end_ver_num > doc.ctrt_ver_num
  )
  INNER JOIN mn_cf_strategy_ver prog ON (
      prog.cf_strategy_id = eligcust.src_id AND
      prog.ver_num <= doc.ctrt_ver_num AND
      prog.end_ver_num > doc.ctrt_ver_num
  )
  INNER JOIN mn_cf_component_ver comp ON (
      comp.cf_component_id = eligcust.bucket_src_id AND
      comp.mgr_id = eligcust.bucket_src_mgr_id AND
      comp.ver_num <= doc.ctrt_ver_num AND
      comp.end_ver_num > doc.ctrt_ver_num
  )
WHERE
  comp.module_type = 'PRICING'
  AND eligcust.is_latest_eligibility = 1;

--Direct Sale Amount,Prompt Pay discount - Summed-up value for a bucket used in price calculation. May be in Workbook result line
select wrl.cat_obj_id,
           wrl.amt2 as net_dollars, wrl.qty1 as net_units, wrl.algorithm, wrl.amt11 as ppd,
           wrl.actual_price_amt as amp
      from mn_workbook_dep wd, mn_workbook w,
           mn_workbook_result wr, mn_workbook_res_line wrl
      where w.workbook_id = wr.workbook_id
            and wr.workbook_result_id = wrl.workbook_result_id
            and wr.workbook_result_type = 'NDC9'
            and w.workbook_id = wd.workbook_id;

