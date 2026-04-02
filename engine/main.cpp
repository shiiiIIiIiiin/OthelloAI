// コンパイル方法：
//   g++ -O2 -o engine main.cpp
//
// 実行方法：
//   GUIアプリでこのexeを選択して対局

#include <bits/stdc++.h>
using namespace std;

// ================================================
// 盤面の定数
// ================================================
const int EMPTY = 0;
const int BLACK = 1;
const int WHITE = 2;

// 8方向ベクトル
const int DR[] = {-1,-1,-1, 0, 0, 1, 1, 1};
const int DC[] = {-1, 0, 1,-1, 1,-1, 0, 1};

// ================================================
// グローバル変数
// ================================================
int board[8][8]; // 盤面
int myColor;     // 自分の色（BLACK or WHITE）

// ================================================
// ユーティリティ
// ================================================

int opponent(int color) {
    return color == BLACK ? WHITE : BLACK;
}

bool inBounds(int r, int c) {
    return r >= 0 && r < 8 && c >= 0 && c < 8;
}

// 64文字の盤面文字列をboard[][]に読み込む
void parseBoard(const string& s) {
    for (int i = 0; i < 64; i++) {
        int r = i / 8, c = i % 8;
        if      (s[i] == 'B') board[r][c] = BLACK;
        else if (s[i] == 'W') board[r][c] = WHITE;
        else                   board[r][c] = EMPTY;
    }
}

// ================================================
// 合法手生成
// ================================================

// (r, c) に color の石を置いたとき、方向 (dr, dc) にひっくり返せるか
bool canFlipDir(int r, int c, int color, int dr, int dc) {
    int opp = opponent(color);
    r += dr; c += dc;
    if (!inBounds(r, c) || board[r][c] != opp) return false;
    r += dr; c += dc;
    while (inBounds(r, c)) {
        if (board[r][c] == EMPTY) return false;
        if (board[r][c] == color) return true;
        r += dr; c += dc;
    }
    return false;
}

// (r, c) が color にとって合法手か
bool isLegal(int r, int c, int color) {
    if (board[r][c] != EMPTY) return false;
    for (int d = 0; d < 8; d++) {
        if (canFlipDir(r, c, color, DR[d], DC[d])) return true;
    }
    return false;
}

// color の合法手一覧を返す
vector<pair<int,int>> legalMoves(int color) {
    vector<pair<int,int>> moves;
    for (int r = 0; r < 8; r++)
        for (int c = 0; c < 8; c++)
            if (isLegal(r, c, color)) moves.push_back({r, c});
    return moves;
}

// (r, c) に color の石を置いて、ひっくり返す
void place(int r, int c, int color) {
    board[r][c] = color;
    for (int d = 0; d < 8; d++) {
        if (!canFlipDir(r, c, color, DR[d], DC[d])) continue;
        int nr = r + DR[d], nc = c + DC[d];
        while (board[nr][nc] != color) {
            board[nr][nc] = color;
            nr += DR[d]; nc += DC[d];
        }
    }
}

// 指し手を文字列に変換（例：(3,4) → "e4"）
string moveToString(int r, int c) {
    string s = "";
    s += (char)('a' + c);
    s += (char)('1' + r);
    return s;
}

// ================================================
// ここから下を実装してください
// ================================================

// 評価関数
// 盤面を見て、自分にとって有利なら大きい値、不利なら小さい値を返す
int evaluate() {
    // とりあえず石の数の差を返す（弱いけど動く）
    int black = 0, white = 0;
    for (int r = 0; r < 8; r++)
        for (int c = 0; c < 8; c++) {
            if (board[r][c] == BLACK) black++;
            if (board[r][c] == WHITE) white++;
        }
    return myColor == BLACK ? black - white : white - black;
}

// 探索
// color の手番で、timeLimitMs ミリ秒以内に指し手を返す
// 戻り値：指し手（例："e4"）またはパス（"pass"）
string search(int color, int timeLimitMs) {
    auto moves = legalMoves(color);
    if (moves.empty()) return "pass";

    // とりあえずランダムに選ぶ
    mt19937 rng(chrono::steady_clock::now().time_since_epoch().count());
    auto [r, c] = moves[rng() % moves.size()];
    return moveToString(r, c);
}

// ================================================
// ここから下は触らなくていいです（プロトコル処理）
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
            cout << "MyOthelloAI" << endl;

        } else if (cmd == "rule") {
            // rule color <B or W> time_per_move <ms> increment <ms>
            string key, colorStr;
            int timePerMove, increment;
            iss >> key >> colorStr >> key >> timePerMove >> key >> increment;
            myColor = (colorStr == "B") ? BLACK : WHITE;

        } else if (cmd == "position") {
            // position <64文字> <B or W> <持ち時間ms>
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
