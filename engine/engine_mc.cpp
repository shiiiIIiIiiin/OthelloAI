// モンテカルロ法によるオセロAI
//
// 各手番の動作：
//   1. 合法手を列挙（c手）
//   2. 各合法手に 持ち時間/c 秒を割り当てる
//   3. 各合法手について、時間の許す限りランダムプレイアウトを繰り返す
//   4. スコア = Σ(勝ったときの石差) / シミュレーション回数
//   5. スコアが最も高い手を選ぶ
//
// コンパイル方法：
//   g++ -O2 -o engine_mc engine_mc.cpp

#include <bits/stdc++.h>
using namespace std;

// ================================================
// 盤面の定数
// ================================================
const int EMPTY = 0;
const int BLACK = 1;
const int WHITE = 2;

const int DR[] = {-1,-1,-1, 0, 0, 1, 1, 1};
const int DC[] = {-1, 0, 1,-1, 1,-1, 0, 1};

// ================================================
// グローバル変数
// ================================================
int board[8][8];
int myColor;
int incrementMs = 1000; // 1手ごとに増える時間（rule コマンドで更新）

mt19937 rng(chrono::steady_clock::now().time_since_epoch().count());


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
// 合法手・石を置く（盤面をコピーして使う）
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
// ランダムプレイアウト
// 盤面bを受け取り、ゲーム終了まで両者ランダムに指す
// 戻り値：myColorの石数 - 相手の石数（正=勝ち、負=負け）
// ================================================
int playout(int b[8][8], int color) {
    int tmp[8][8];
    memcpy(tmp, b, sizeof(tmp));

    int cur = color;
    int passCnt = 0;

    while (true) {
        auto moves = legalMoves(tmp, cur);
        if (moves.empty()) {
            passCnt++;
            if (passCnt >= 2) break; // 両者パス → 終了
            cur = opponent(cur);
            continue;
        }
        passCnt = 0;
        auto [r, c] = moves[rng() % moves.size()];
        place(tmp, r, c, cur);
        cur = opponent(cur);
    }

    // 石数を数える
    int black = 0, white = 0;
    for (int r = 0; r < 8; r++)
        for (int c = 0; c < 8; c++) {
            if (tmp[r][c] == BLACK) black++;
            if (tmp[r][c] == WHITE) white++;
        }

    return myColor == BLACK ? black - white : white - black;
}

// ================================================
// 探索（モンテカルロ法）
// ================================================
string search(int color, int timeLimitMs) {
    auto moves = legalMoves(board, color);
    if (moves.empty()) return "pass";
    if (moves.size() == 1) return moveToString(moves[0].first, moves[0].second);

    // GUIから渡された持ち時間を各手に均等に配分（500ms余裕を残す）
    int timePerMove = max(0, timeLimitMs - 500) / (int)moves.size();


    int bestIdx = 0;
    double bestScore = -1e18;

    for (int i = 0; i < (int)moves.size(); i++) {
        auto [r, c] = moves[i];

        // この手を指した後の盤面を作る
        int tmp[8][8];
        memcpy(tmp, board, sizeof(tmp));
        place(tmp, r, c, color);

        // 時間の許す限りプレイアウト
        auto start = chrono::steady_clock::now();
        long long totalScore = 0;
        int simCount = 0;

        while (true) {
            auto now = chrono::steady_clock::now();
            int elapsed = chrono::duration_cast<chrono::milliseconds>(now - start).count();
            if (elapsed >= timePerMove) break;

            int diff = playout(tmp, opponent(color));
            totalScore += diff;
            simCount++;
        }

        double score = simCount > 0 ? (double)totalScore / simCount : 0.0;

        if (score > bestScore) {
            bestScore = score;
            bestIdx = i;
        }
    }

    return moveToString(moves[bestIdx].first, moves[bestIdx].second);
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
            cout << "MonteCarlo" << endl;

        } else if (cmd == "rule") {
            string key, colorStr;
            int timePerMove, increment;
            iss >> key >> colorStr >> key >> timePerMove >> key >> increment;
            myColor = (colorStr == "B") ? BLACK : WHITE;
            incrementMs = increment;

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
