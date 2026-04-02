// 完全読みの速度テスト
// 様々な局面でsolveExactが何秒かかるか測定する
//
// コンパイル方法：
//   g++ -O2 -o test_exact test_exact.cpp
//
// 使い方：
//   ./test_exact.exe [空きマス数] [試行回数]
//   例: ./test_exact.exe 16 20   ← 空き16マスの局面を20個テスト

#include <bits/stdc++.h>
using namespace std;

const int EMPTY = 0;
const int BLACK = 1;
const int WHITE = 2;
const int INF = 1e9;

const int DR[] = {-1,-1,-1, 0, 0, 1, 1, 1};
const int DC[] = {-1, 0, 1,-1, 1,-1, 0, 1};

mt19937 rng(42); // 再現性のため固定シード

int opponent(int color) { return color == BLACK ? WHITE : BLACK; }
bool inBounds(int r, int c) { return r >= 0 && r < 8 && c >= 0 && c < 8; }

bool canFlipDir(int b[8][8], int r, int c, int color, int dr, int dc) {
    int opp = opponent(color);
    r += dr; c += dc;
    if (!inBounds(r, c) || b[r][c] != opp) return false;
    r += dr; c += dc;
    while (inBounds(r, c)) {
        if (b[r][c] == EMPTY) return false;
        if (b[r][c] == color) return true;
        r += dr; c += dc;
    }
    return false;
}

bool isLegal(int b[8][8], int r, int c, int color) {
    if (b[r][c] != EMPTY) return false;
    for (int d = 0; d < 8; d++)
        if (canFlipDir(b, r, c, color, DR[d], DC[d])) return true;
    return false;
}

vector<pair<int,int>> legalMoves(int b[8][8], int color) {
    vector<pair<int,int>> moves;
    for (int r = 0; r < 8; r++)
        for (int c = 0; c < 8; c++)
            if (isLegal(b, r, c, color)) moves.push_back({r, c});
    return moves;
}

void place(int b[8][8], int r, int c, int color) {
    b[r][c] = color;
    for (int d = 0; d < 8; d++) {
        if (!canFlipDir(b, r, c, color, DR[d], DC[d])) continue;
        int nr = r + DR[d], nc = c + DC[d];
        while (b[nr][nc] != color) {
            b[nr][nc] = color;
            nr += DR[d]; nc += DC[d];
        }
    }
}

int countEmpty(int b[8][8]) {
    int cnt = 0;
    for (int r = 0; r < 8; r++)
        for (int c = 0; c < 8; c++)
            if (b[r][c] == EMPTY) cnt++;
    return cnt;
}

// 完全読み（黒視点の石差を返す）
int solveExact(int b[8][8], int color, int alpha, int beta) {
    auto moves = legalMoves(b, color);
    if (moves.empty()) {
        auto oppMoves = legalMoves(b, opponent(color));
        if (oppMoves.empty()) {
            int black = 0, white = 0;
            for (int r = 0; r < 8; r++)
                for (int c = 0; c < 8; c++) {
                    if (b[r][c] == BLACK) black++;
                    if (b[r][c] == WHITE) white++;
                }
            return black - white;
        }
        return solveExact(b, opponent(color), alpha, beta);
    }
    if (color == BLACK) {
        int best = -INF;
        for (auto [r, c] : moves) {
            int tmp[8][8]; memcpy(tmp, b, sizeof(tmp));
            place(tmp, r, c, color);
            best = max(best, solveExact(tmp, opponent(color), alpha, beta));
            alpha = max(alpha, best);
            if (alpha >= beta) break;
        }
        return best;
    } else {
        int best = INF;
        for (auto [r, c] : moves) {
            int tmp[8][8]; memcpy(tmp, b, sizeof(tmp));
            place(tmp, r, c, color);
            best = min(best, solveExact(tmp, opponent(color), alpha, beta));
            beta = min(beta, best);
            if (alpha >= beta) break;
        }
        return best;
    }
}

// ランダムに対局を進めて空きマスがtargetEmptyの局面を作る
// 失敗したらfalseを返す
bool generatePosition(int b[8][8], int& color, int targetEmpty) {
    // 初期配置
    for (int r = 0; r < 8; r++) for (int c = 0; c < 8; c++) b[r][c] = EMPTY;
    b[3][3] = WHITE; b[3][4] = BLACK;
    b[4][3] = BLACK; b[4][4] = WHITE;
    color = BLACK;

    int passCnt = 0;
    while (countEmpty(b) > targetEmpty) {
        auto moves = legalMoves(b, color);
        if (moves.empty()) {
            passCnt++;
            if (passCnt >= 2) return false; // 終局してしまった
            color = opponent(color);
            continue;
        }
        passCnt = 0;
        auto [r, c] = moves[rng() % moves.size()];
        place(b, r, c, color);
        color = opponent(color);
    }
    return true;
}

int main(int argc, char* argv[]) {
    int targetEmpty = argc > 1 ? atoi(argv[1]) : 16;
    int trials      = argc > 2 ? atoi(argv[2]) : 20;

    cout << "空きマス数: " << targetEmpty << "  試行回数: " << trials << endl;
    cout << string(50, '-') << endl;

    double totalMs = 0;
    double maxMs = 0;
    int success = 0;

    for (int i = 0; i < trials; i++) {
        int b[8][8], color;
        if (!generatePosition(b, color, targetEmpty)) {
            cout << "試行" << i+1 << ": 局面生成失敗（終局）" << endl;
            continue;
        }

        auto start = chrono::steady_clock::now();
        solveExact(b, color, -INF, INF);
        double ms = chrono::duration_cast<chrono::microseconds>(
            chrono::steady_clock::now() - start).count() / 1000.0;

        cout << "試行" << setw(3) << i+1 << ": " << fixed << setprecision(1) << ms << "ms" << endl;
        totalMs += ms;
        maxMs = max(maxMs, ms);
        success++;
    }

    cout << string(50, '-') << endl;
    cout << "平均: " << fixed << setprecision(1) << totalMs / success << "ms" << endl;
    cout << "最大: " << fixed << setprecision(1) << maxMs << "ms" << endl;

    return 0;
}
