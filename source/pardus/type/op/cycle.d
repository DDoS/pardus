module pardus.type.op.cycle;

class Cycles(T, size_t N) if (N > 0) {
    struct Node {
        T[N] n;
    }
    bool[Node] path;

    bool traverse(T[N] n...) {
        auto node = Node(n);
        if (node in path) {
            return true;
        }
        path[node] = true;
        return false;
    }
}
