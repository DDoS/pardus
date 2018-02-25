module pardus.cycle;

class BiCycles(T) {
    struct Node {
        T a;
        T b;
    }
    bool[Node] path;

    bool traverse(T a, T b) {
        auto node = Node(a, b);
        if (node in path) {
            return true;
        }
        path[node] = true;
        return false;
    }
}
