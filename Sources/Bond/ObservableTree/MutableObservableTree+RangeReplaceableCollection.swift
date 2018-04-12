//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 DeclarativeHub/Bond
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

extension MutableObservableTree where UnderlyingTreeNode.NodeCollection: RangeReplaceableCollection {
    /// Append `newElement` at the end of the collection.
    public func append(_ newElement: UnderlyingTreeNode.NodeCollection.Element) {
        descriptiveUpdate { (node) -> [TreeOperation] in
            node.children.append(newElement)
            let insertionIndex = node.children.index(node.children.endIndex, offsetBy: -1)
            return [.insert(at: node.indexPath.appending(insertionIndex))]
        }
    }

    /// Insert `newElement` at index `i`.
    public func insert(_ newElement: UnderlyingTreeNode.NodeCollection.Element, at index: IndexPath) {
        descriptiveUpdate { (_) -> [TreeOperation] in
            var parent = node[index.dropLast()]
            parent.children.insert(newElement, at: index.item)
            return [.insert(at: index)]
        }
    }

    /// Insert elements `newElements` at index `i`.
    public func insert(contentsOf newElements: [UnderlyingTreeNode.NodeCollection.Element], at index: IndexPath) {
        descriptiveUpdate { (node) -> [TreeOperation] in
            var parent = node[index.dropLast()]
            for newElement in newElements.reversed() {
                parent.children.insert(newElement, at: index.item)
            }
            let endIndex = offsetIndex(index.item, by: newElements.count)
            let indices = indexes(from: index.item, to: endIndex)
            return indices.map { TreeOperation.insert(at: parent.indexPath.appending($0)) }
        }
    }

    /// Move the element at index `i` to index `toIndex`.
    public func moveItem(from fromIndex: IndexPath, to toIndex: IndexPath) {
        descriptiveUpdate { (node) -> [TreeOperation] in
            var parentFrom = node[fromIndex.dropLast()]
            var parentTo = node[toIndex.dropLast()]
            let item = parentFrom.children.remove(at: fromIndex.item)
            parentTo.children.insert(item, at: toIndex.item)
            return [.move(from: fromIndex, to: toIndex)]
        }
    }

    /// Remove and return the element at index i.
    @discardableResult
    public func remove(at index: IndexPath) -> UnderlyingTreeNode.NodeCollection.Element {
        return descriptiveUpdate { (node) -> ([TreeOperation], UnderlyingTreeNode.NodeCollection.Element) in
            var parent = node[index.dropLast()]
            let element = parent.children.remove(at: index.item)
            return ([.delete(at: index)], element)
        }
    }

    /// Remove an element from the end of the collection in O(1).
    @discardableResult
    public func removeLast() -> UnderlyingTreeNode.NodeCollection.Element {
        return descriptiveUpdate { (node) -> ([TreeOperation], UnderlyingTreeNode.NodeCollection.Element) in
            let index = node.children.index(node.endIndex, offsetBy: -1)
            let element = node.children.remove(at: index)
            return ([.delete(at: node.indexPath.appending(index))], element)
        }
    }

    /// Remove all elements from the collection.
    public func removeAll() {
        descriptiveUpdate { (node) -> [TreeOperation] in
            let indexPath = node.indexPath
            let diff = node.children.indices
                .map { indexPath.appending($0) }
                .map { TreeOperation.delete(at: $0)}
            node.children.removeAll(keepingCapacity: false)
            return diff
        }
    }
}
