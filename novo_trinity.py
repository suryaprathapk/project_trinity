from ete3 import Tree

def fill_tree(parent_node, formula_input):
    param =''
    for char in formula_input:
        if char in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890$_() ":
            param  += char
        elif char in "+-*\/^":
            param = parent_node.add_child(name="{}".format(param))
            param =""
    if param:
        param = parent_node.add_child(name="{}".format(param))
        param =""

input_formula = {
"net_dollars": "total_direct_sale$-total_indirect_sale$-total_chargebacks$-total_rebate_fee$-smoothed_excludable_rebates$-total_adjustments$",
"net_units": "total_direct_units-total_indirect_units-wholesaler_excludable_rebate_units",
"total_direct_sale$": "direct_sale_discounted_customer$ * prompt_pay_discount",
"total  _indirect_sale$": "wac_proxy * 1-prompt_pay_discount * total_indirect_units",
"endo_thokka": "emiledhu"
}

AMP =Tree()
fill_tree(AMP, "net_dollars/net_units")
for key, value in input_formula.items():
    try:
        if AMP.search_nodes(name = key)[0] is not NULL :
            fill_tree(AMP.search_nodes(name = key)[0], value)
    except:
        print("node {} doesn't exist in tree".format(key)

print(AMP.get_ascii(show_internal=True))