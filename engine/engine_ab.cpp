// αβ探索によるオセロAI
//
// コンパイル方法：
//   g++ -O2 -o engine_ab engine_ab.cpp

#include <bits/stdc++.h>
using namespace std;

// ================================================
// 盤面の定数
// ================================================
const int EMPTY = 0;
const int BLACK = 1;
const int WHITE = 2;
const int INF = 1e9;

const int DR[] = {-1,-1,-1, 0, 0, 1, 1, 1};
const int DC[] = {-1, 0, 1,-1, 1,-1, 0, 1};

// ================================================
// グローバル変数
// ================================================
int board[8][8];
int myColor;

// ================================================
// ユーティリティ
// ================================================
int opponent(int color) { return color == BLACK ? WHITE : BLACK; }
bool inBounds(int r, int c) { return r >= 0 && r < 8 && c >= 0 && c < 8; }

void parseBoard(const string& s) {
    for (int i = 0; i < 64; i++) {
        int r = i / 8, c = i % 8;
        if      (s[i] == 'B') board[r][c] = BLACK;
        else if (s[i] == 'W') board[r][c] = WHITE;
        else                   board[r][c] = EMPTY;
    }
}

string moveToString(int r, int c) {
    string s = "";
    s += (char)('a' + c);
    s += (char)('1' + r);
    return s;
}

// ================================================
// 合法手・石を置く
// ================================================
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

// ================================================
// 評価関数
// ================================================

// マスごとの重み（角は高く、角の隣は低く）
const int WEIGHT[8][8] = {
    { 100, -20,  10,   5,   5,  10, -20, 100},
    { -20, -40,  -5,  -5,  -5,  -5, -40, -20},
    {  10,  -5,   5,   1,   1,   5,  -5,  10},
    {   5,  -5,   1,   0,   0,   1,  -5,   5},
    {   5,  -5,   1,   0,   0,   1,  -5,   5},
    {  10,  -5,   5,   1,   1,   5,  -5,  10},
    { -20, -40,  -5,  -5,  -5,  -5, -40, -20},
    { 100, -20,  10,   5,   5,  10, -20, 100},
};

// 盤面を評価する（myColorにとって有利なら大きい値）
int evaluate(int b[8][8]) {
    int score = 0;
    for (int r = 0; r < 8; r++)
        for (int c = 0; c < 8; c++) {
            if      (b[r][c] == myColor)           score += WEIGHT[r][c];
            else if (b[r][c] == opponent(myColor))  score -= WEIGHT[r][c];
        }
    return score;
}

// ================================================
// αβ探索
// ================================================
// color: 今の手番
// alpha: 自分がこれ以上良い手を見つけているなら枝刈り
// beta:  相手がこれ以上良い手を見つけているなら枝刈り
// 戻り値：myColorにとっての評価値
int alphabeta(int b[8][8], int color, int depth, int alpha, int beta) {
    auto moves = legalMoves(b, color);

    // 終局チェック（両者パスなら終局）
    if (moves.empty()) {
        auto oppMoves = legalMoves(b, opponent(color));
        if (oppMoves.empty()) {
            // 終局 → 石数で勝敗
            int black = 0, white = 0;
            for (int r = 0; r < 8; r++)
                for (int c = 0; c < 8; c++) {
                    if (b[r][c] == BLACK) black++;
                    if (b[r][c] == WHITE) white++;
                }
            int diff = myColor == BLACK ? black - white : white - black;
            return diff > 0 ? INF : (diff < 0 ? -INF : 0);
        }
        // パス → 手番を交代して続ける
        return alphabeta(b, opponent(color), depth, alpha, beta);
    }

    // 深さ制限に達したら評価値を返す
    if (depth == 0) return evaluate(b);

    if (color == myColor) {
        // 自分の手番 → 最大化
        int best = -INF;
        for (auto [r, c] : moves) {
            int tmp[8][8];
            memcpy(tmp, b, sizeof(tmp));
            place(tmp, r, c, color);
            best = max(best, alphabeta(tmp, opponent(color), depth - 1, alpha, beta));
            alpha = max(alpha, best);
            if (alpha >= beta) break; // βカット
        }
        return best;
    } else {
        // 相手の手番 → 最小化
        int best = INF;
        for (auto [r, c] : moves) {
            int tmp[8][8];
            memcpy(tmp, b, sizeof(tmp));
            place(tmp, r, c, color);
            best = min(best, alphabeta(tmp, opponent(color), depth - 1, alpha, beta));
            beta = min(beta, best);
            if (alpha >= beta) break; // αカット
        }
        return best;
    }
}

// ================================================
// 探索
// ================================================
string search(int color, int timeLimitMs) {
    auto moves = legalMoves(board, color);
    if (moves.empty()) return "pass";
    if (moves.size() == 1) return moveToString(moves[0].first, moves[0].second);

    auto startTime = chrono::steady_clock::now();

    int bestRow = moves[0].first, bestCol = moves[0].second;
    int bestScore = -INF;

    // 深さを1から増やしながら探索（時間が許す限り深く）
    for (int depth = 1; depth <= 20; depth++) {
        int curBestRow = moves[0].first, curBestCol = moves[0].second;
        int curBestScore = -INF;

        for (auto [r, c] : moves) {
            // 時間チェック（制限の80%を超えたら打ち切り）
            auto now = chrono::steady_clock::now();
            int elapsed = chrono::duration_cast<chrono::milliseconds>(now - startTime).count();
            if (elapsed >= timeLimitMs * 8 / 10) goto done;

            int tmp[8][8];
            memcpy(tmp, board, sizeof(tmp));
            place(tmp, r, c, color);
            int score = alphabeta(tmp, opponent(color), depth - 1, -INF, INF);

            if (score > curBestScore) {
                curBestScore = score;
                curBestRow = r;
                curBestCol = c;
            }
        }

        // この深さまで読み切れたら結果を確定
        bestRow = curBestRow;
        bestCol = curBestCol;
        bestScore = curBestScore;
    }

    done:
    return moveToString(bestRow, bestCol);
}

// ================================================
// プロトコル処理（触らなくていい）
// ================================================
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    string line;
    while (getline(cin, line)) {
        if (line.empty()) continue;
        istringstream iss(line);
        string cmd;
        iss >> cmd;

        if (cmd == "name") {
            cout << "AlphaBeta" << endl;

        } else if (cmd == "rule") {
            string key, colorStr;
            int timePerMove, increment;
            iss >> key >> colorStr >> key >> timePerMove >> key >> increment;
            myColor = (colorStr == "B") ? BLACK : WHITE;

        } else if (cmd == "position") {
            string boardStr, colorStr;
            int timeLimitMs;
            iss >> boardStr >> colorStr >> timeLimitMs;
            parseBoard(boardStr);
            int color = (colorStr == "B") ? BLACK : WHITE;
            cout << search(color, timeLimitMs) << endl;

        } else if (cmd == "quit") {
            break;
        }
    }
    return 0;
}
