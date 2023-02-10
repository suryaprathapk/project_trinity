class Node:
    def __init__(self, value):
        self.value = value
        self.children = []

def formula_to_tree(formula):
    stack = []
    for char in formula:
        if char == '(':
            stack.append(Node(char))
        elif char.isalpha():
            stack[-1].children.append(Node(char))
        elif char == ')':
            node = stack.pop()
            if stack:
                stack[-1].children.append(node)
            else:
                return node

formula = "((A+B)*(C-D))"
root = formula_to_tree(formula)
print(root)