from graphviz import Digraph
# import os
# os.environ["PATH"] += os.pathsep + 'C:\suryas\Software\Graphviz\bin'
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
def build_graph(root, graph):
    if not root:
        return
    for child in root.children:
        graph.edge(root.value, child.value)
        build_graph(child, graph)

formula = "((A+B)*(C-D))"
root = formula_to_tree(formula)

graph = Digraph(name='Formula Tree')
build_graph(root, graph)
graph.render('formula_tree')
