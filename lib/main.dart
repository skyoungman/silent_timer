// ------------------------------------------------------------
// 1. 必要なライブラリ（道具箱）を取り込むインポート部分
// ------------------------------------------------------------
import 'dart:async'; // タイマー機能（Timer.periodic）を使うためのDart標準ライブラリ
import 'package:flutter/cupertino.dart'; // iOS風デザイン（CupertinoPickerドラムロール）用
import 'package:flutter/material.dart'; // Flutter標準のデザインパーツ（ボタン、テキスト、テーマ色など）用
import 'package:flutter/services.dart'; // スマホのハードウェア制御（バイブレーション HapticFeedback）用

// ------------------------------------------------------------
// 2. アプリのスタート地点（メイン関数）
// ------------------------------------------------------------
void main() {
  // アプリを起動し、最初に MyApp クラス（全体設定）を立ち上げる
  runApp(const SilentTimerApp());
}

// ------------------------------------------------------------
// 3. アプリ全体の設定・外枠を決めるクラス（見た目が変わらない枠組み）
// ------------------------------------------------------------
class SilentTimerApp extends StatelessWidget {
  const SilentTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Silent Timer', // アプリの内部名称
      theme: ThemeData(
        useMaterial3: true, // 最新のマテリアルデザイン3を有効化
        colorSchemeSeed: Colors.blue, // アプリ全体のテーマカラー（基調色）を「青」に設定
      ),
      home: const TimerHomePage(), // 起動時に最初に表示するメイン画面を指定
    );
  }
}

// ------------------------------------------------------------
// 4. メイン画面の定義（数値や表示が動的に変化する画面）
// ------------------------------------------------------------
class TimerHomePage extends StatefulWidget {
  const TimerHomePage({super.key});

  @override
  // 画面のデータ（状態）を管理する _TimerHomePageState と紐付けを行う
  State<TimerHomePage> createState() => _TimerHomePageState();
}

// ------------------------------------------------------------
// 5. メイン画面の実体（変数・ロジック・UIのすべてがここに入る）
// ------------------------------------------------------------
class _TimerHomePageState extends State<TimerHomePage> {
  // ---【変数宣言：ドラムロールで選んだ時間を保持する変数】---
  int selectedHour = 0; // 選択された「時間」
  int selectedMin = 0; // 選択された「分」
  int selectedSec = 0; // 選択された「秒」

  // ---【変数宣言：タイマーの動作状態を管理するフラグ】---
  bool isRunning = false; // タイマーが作動中かどうか（true: 作動中, false: 停止中）
  bool isPaused = false; // 一時停止中かどうか（true: 一時停止中, false: カウントダウン中）
  int remainingTime = 0; // カウントダウンの残り時間（秒単位）
  Timer? timer; // 1秒ごとに処理を繰り返すためのタイマーオブジェクト（nullの可能性あり）

  // ---【変数宣言：設定スイッチと画面色の状態】---
  bool flashSwitch = true; // 画面点滅機能のON/OFF
  bool vibeSwitch = true; // バイブレーション機能のON/OFF
  Color bgColor = const Color.fromARGB(255, 255, 255, 255); // 画面の背景色（通常は白、アラーム時は赤に変わる）

  // ---【変数宣言：ドラムロールの位置をプログラムから動かすためのコントローラー】---
  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minController;
  late FixedExtentScrollController secController;

  @override
  void initState() {
    super.initState();
    // 画面が最初に読み込まれた時に、ドラムロールの初期位置をすべて「0」に設定する
    hourController = FixedExtentScrollController(initialItem: 0);
    minController = FixedExtentScrollController(initialItem: 0);
    secController = FixedExtentScrollController(initialItem: 0);
  }

  // ---【ロジック 1：開始・一時停止・再開ボタンを押した時の処理】---
  void startTimer() {
    // ① 作動中で一時停止していない場合 ➔ 「一時停止」にする
    if (isRunning && !isPaused) {
      setState(() {
        isPaused = true;
      });
      timer?.cancel(); // カウントダウンを一時ストップ
      return;
    }

    // ② 作動中で一時停止中の場合 ➔ カウントダウンを「再開」する
    if (isRunning && isPaused) {
      setState(() {
        isPaused = false;
      });
      runCountdown(); // カウントダウン処理を再開
      return;
    }

    // ③ 新しくタイマーをスタートする場合 ➔ 総秒数を計算
    int totalSec = selectedHour * 3600 + selectedMin * 60 + selectedSec;
    if (totalSec <= 0) return; // 0秒の場合はスタートしない

    setState(() {
      remainingTime = totalSec; // 残り時間をセット
      isRunning = true; // 作動中フラグをON
      isPaused = false; // 一時停止フラグをOFF
    });

    runCountdown(); // カウントダウン開始
  }

  // ---【ロジック 2：1秒ごとに残り時間を減らすカウントダウン処理】---
  void runCountdown() {
    // 1秒ごと（Duration(seconds: 1)）に定期的に中の処理を実行
    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (remainingTime > 0) {
        // まだ時間が残っている場合：残り時間を1秒減らして画面を更新（setState）
        setState(() {
          remainingTime--;
        });
      } else {
        // 残り時間が0になった場合：タイマーを停止してアラーム演出を実行
        t.cancel();
        setState(() {
          isRunning = false;
          isPaused = false;
        });
        await triggerAlarmEffect(); // 点滅と振動のアラームを実行
      }
    });
  }

  // ---【ロジック 3：キャンセルボタンを押した時の処理】---
  void cancelTimer() {
    timer?.cancel(); // タイマーの定期実行をストップ
    setState(() {
      isRunning = false;
      isPaused = false;
      remainingTime = 0; // 残り時間をリセット
    });
  }

// ---【ロジック 4：タイマー終了時のアラーム演出（点滅・強力バイブ・手動停止まで無限ループ）】---
  Future<void> triggerAlarmEffect() async {
    bool isAlarming = true; // アラーム停止管理フラグ

    if (!mounted) return;

    // ポップアップダイアログを先に表示（OKボタンを押すまで閉じない設定）
    showDialog(
      context: context,
      barrierDismissible: false, // ダイアログ外のタップで閉じないように保護
      builder: (context) => AlertDialog(
        title: const Text("時間になりました"),
        content: const Text("お疲れさまでした"),
        actions: [
          TextButton(
            onPressed: () {
              isAlarming = false; // ループを止める
              Navigator.pop(context); // ダイアログを閉じる
            },
            child: const Text("停止", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          )
        ],
      ),
    );

    // ユーザーが「停止」を押すまで無限に繰り返す
    while (isAlarming && mounted) {
      if (flashSwitch) {
        setState(() => bgColor = Colors.red.shade200); // 赤点滅
      }

      if (vibeSwitch) {
        // バイブ強化：短時間（100ms間隔）で2回連続衝撃を与えて振動感を強める
        HapticFeedback.vibrate();
        
      }

      await Future.delayed(const Duration(milliseconds: 250));

      if (flashSwitch) {
        setState(() => bgColor = const Color.fromARGB(255, 255, 255, 255)); // 白に戻す
      }

      await Future.delayed(const Duration(milliseconds: 250));
    }

    // 停止後に背景色を必ず白に戻す
    if (mounted) {
      setState(() => bgColor = const Color.fromARGB(255, 255, 255, 255));
    }
  }

  // ---【ロジック 5：テンプレートボタンを押した時に時間をセットする処理】---
  void setTemplateTime(int h, int m, int s) {
    if (isRunning) return; // タイマー作動中はテンプレート変更を受け付けない
    setState(() {
      selectedHour = h;
      selectedMin = m;
      selectedSec = s;
    });
    // ドラムロールの見た目のスクロール位置をセットした時間に強制ジャンプさせる
    hourController.jumpToItem(h);
    minController.jumpToItem(m);
    secController.jumpToItem(s);
  }

  // ---【ロジック 6：秒数を「00:00:00」形式の文字列に変換するヘルパー関数】---
  String formatTime(int totalSeconds) {
    int h = totalSeconds ~/ 3600; // 時間の計算（整数除算）
    int m = (totalSeconds % 3600) ~/ 60; // 分の計算
    int s = totalSeconds % 60; // 秒の計算
    // 桁数を揃えて「01:05:09」のように2桁埋め（padLeft）して返す
    return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // ------------------------------------------------------------
  // 6. UI（画面のレイアウトと見た目）を構築する部分
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor, // アラーム演出で変わる背景色を適用
      body: SafeArea(
        // ノッチやステータスバーに被らない安全なエリア内に配置
        child: ListView(
          padding: const EdgeInsets.all(20), // 画面端から20pxの余白を空ける
          children: [
            // ---【タイトル表示】---
            const Center(
              child: Text(
                "Silent Timer",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
            const Divider(height: 10), // 区切り線

            const Text(
              "タイマーセット",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // ---【タイマーセット画面：停止中と作動中で表示を切り替え】---
            if (!isRunning)
              // 【停止中】iOS風の時間選択ピッカー（ドラムロール）を表示
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 「時間」ピッカー
                  SizedBox(
                    width: 80,
                    height: 150,
                    child: CupertinoPicker(
                      scrollController: hourController,
                      itemExtent: 32,
                      onSelectedItemChanged: (v) => selectedHour = v,
                      children: List.generate(24, (i) => Center(child: Text(i.toString().padLeft(2, '0')))),
                    ),
                  ),
                  const Text(":", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  // 「分」ピッカー
                  SizedBox(
                    width: 80,
                    height: 150,
                    child: CupertinoPicker(
                      scrollController: minController,
                      itemExtent: 32,
                      onSelectedItemChanged: (v) => selectedMin = v,
                      children: List.generate(60, (i) => Center(child: Text(i.toString().padLeft(2, '0')))),
                    ),
                  ),
                  const Text(":", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                  // 「秒」ピッカー
                  SizedBox(
                    width: 80,
                    height: 150,
                    child: CupertinoPicker(
                      scrollController: secController,
                      itemExtent: 32,
                      onSelectedItemChanged: (v) => selectedSec = v,
                      children: List.generate(60, (i) => Center(child: Text(i.toString().padLeft(2, '0')))),
                    ),
                  ),
                ],
              )
            else
              // 【作動中】巨大なカウントダウン数字（00:00:00）を表示
              Center(
                child: Text(
                  formatTime(remainingTime),
                  style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                ),
              ),

            const SizedBox(height: 15),

            // ---【操作ボタン：キャンセル / 開始・一時停止・再開】---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // キャンセルボタン
                OutlinedButton(
                  onPressed: cancelTimer,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(120, 50)),
                  child: const Text("キャンセル"),
                ),
                const SizedBox(width: 15),
                // 開始・一時停止・再開ボタン（状態によってテキストが動的に変化）
                ElevatedButton(
                  onPressed: startTimer,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(140, 50)),
                  child: Text(
                    !isRunning
                        ? "開始"
                        : isPaused
                            ? "再開"
                            : "一時停止",
                  ),
                ),
              ],
            ),

            const Divider(height: 30),

            // ---【テンプレートボタンセクション】---
            const Text("テンプレート", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // ポモドーロテンプレートボタン（5分 / 25分）
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(onPressed: () => setTemplateTime(0, 5, 0), child: const Text("ポモドーロ\n5:00", textAlign: TextAlign.center)),
                const SizedBox(width: 10),
                OutlinedButton(onPressed: () => setTemplateTime(0, 25, 0), child: const Text("ポモドーロ\n25:00", textAlign: TextAlign.center)),
              ],
            ),
            const SizedBox(height: 10),
            // 講義テンプレートボタン（1時間 / 1時間30分）
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(onPressed: () => setTemplateTime(1, 0, 0), child: const Text("講義１\n1:00:00", textAlign: TextAlign.center)),
                const SizedBox(width: 10),
                OutlinedButton(onPressed: () => setTemplateTime(1, 30, 0), child: const Text("講義２\n1:30:00", textAlign: TextAlign.center)),
              ],
            ),

            const Divider(height: 30),

            // ---【設定スイッチセクション（画面点滅 / バイブ）】---
            const Text("設定", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("画面点滅"),
                Switch(value: flashSwitch, onChanged: (v) => setState(() => flashSwitch = v)),
                const SizedBox(width: 20),
                const Text("バイブ"),
                Switch(value: vibeSwitch, onChanged: (v) => setState(() => vibeSwitch = v)),
              ],
            ),
          ],
        ),
      ),

      // ---【画面下部のナビゲーションバー（セット / 一覧）】---
      // まだ「一覧」画面は作っていないので、ナビゲーションバーは表示だけしておく
      //bottomNavigationBar: NavigationBar(
        //destinations: const [
          //NavigationDestination(icon: Icon(Icons.timer), label: "セット"),
          //NavigationDestination(icon: Icon(Icons.format_list_bulleted), label: "一覧"),
        //],
        //electedIndex: 0,
      //),
      //
    );
  }
}