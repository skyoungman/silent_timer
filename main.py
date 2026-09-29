import flet as ft
import asyncio

def main(page: ft.Page):
    #タイマーが動いているか
    is_running = False
    #残り何秒か
    remaining_time = 0

    #ーーー１．画面の基本設定　ーーー
    page.title = "無音タイマー"
    page.window.width = 400
    page.window.height = 700
    page.padding = 20 #画面端からの余白

    #ーーー２．UIコントロールのインスタンス化　ーーー
    
    #2-1.タイトル（Textクラス）
    title = ft.Text("無音タイマー", size = 18, weight=ft.FontWeight.NORMAL,color = ft.Colors.GREY_500,font_family="MS Mincho")

    #2-2.時間設定フォーム（TextFieldクラスとRowクラス）
    timer_title = ft.Text("タイマーセット", size = 18 , weight=ft.FontWeight.BOLD)

    hour_picker = ft.CupertinoPicker(
         selected_index = 0,
         item_extent = 32,
         controls = [ft.Text(f"{i:02}", size = 20) for i in range (24)]
    )

    min_picker = ft.CupertinoPicker(
         selected_index = 0,
         item_extent = 32,
         controls = [ft.Text(f"{i:02}", size = 20) for i in range (60)]
    )

    sec_picker = ft.CupertinoPicker(
         selected_index = 0,
         item_extent = 32,
         controls = [ft.Text(f"{i:02}", size = 20) for i in range (60)]
    )

    picker_row = ft.Row(
         controls = [
              ft.Container(content = hour_picker, width = 80, height = 150),
              ft.Text(":", size = 30, weight = ft.FontWeight.BOLD),
              ft.Container(content = min_picker, width = 80, height = 150),
              ft.Text(":", size = 30, weight = ft.FontWeight.BOLD),
              ft.Container(content = sec_picker, width = 80, height = 150),
         ],
         alignment = ft.MainAxisAlignment.CENTER
    )

    countdown_display = ft.Text(
         value = "00:00:00",
         size = 50,
         weight = ft.FontWeight.BOLD,
         visible = False
    )

    #ボタンを押したときに実行される関数
    async def countdown():
        nonlocal is_running, remaining_time
        while is_running and remaining_time > 0:
            await asyncio.sleep(1)
            if not is_running:
                break
            remaining_time -= 1

            h = remaining_time // 3600
            m = (remaining_time % 3600) // 60
            s = remaining_time % 60
            countdown_display.value = f"{h:02}:{m:02}:{s:02}"
            page.update()

        if remaining_time <= 0:
            is_running = False
            #見た目をもとに戻す（ピッカー復活）
            picker_row.visible = True
            countdown_display.visible = False
        

            #ーーー画面の点滅（フラッシュ演出）ーーー
            original_bgcolor = page.bgcolor #元の背景色を記憶しておく

            for _ in range(3):
                 page.bgcolor = ft.Colors.RED_400
                 page.update()
                 await asyncio.sleep(0.3)

                 page.bgcolor = original_bgcolor
                 page.update()
                 await asyncio.sleep(0.3)

            #ーーーポップアップ（ダイアログ）の表示ーーー
            dlg = ft.AlertDialog(
                 title=ft.Text("時間になりました"),
                 content=ft.Text("お疲れさまでした")
            ) 
            #ダイアログを画面に開く
            page.overlay.append(dlg)
            dlg.open = True

            page.update()

    async def on_start_click(e):
        nonlocal is_running, remaining_time
        if is_running:
            return

        #ピッカーで選べばれている数字を取得
        h = hour_picker.selected_index
        m = min_picker.selected_index
        s = sec_picker.selected_index

        #時、分、秒をすべて秒に変換して合計する
        remaining_time = h * 3600 + m * 60 + s

        #０秒スタートの帽子
        if remaining_time <= 0:
             return

        is_running = True

        picker_row.visible = False
        countdown_display.visible = True

        countdown_display.value = f"{h:02}:{m:02}:{s:02}"
        page.update()

        page.run_task(countdown)

    def on_cancel_click(e):
        nonlocal is_running
        is_running = False
        picker_row.visible = True
        countdown_display.visible = False
        page.update()

    #テンプレートボタンによるピッカーの表示更新関数
    def set_picker_time(h, m ,s):
        nonlocal hour_picker, min_picker, sec_picker

        #ピッカーの作り直し
        hour_picker = ft.CupertinoPicker(selected_index = h, item_extent = 32, controls = [ft.Text(f"{i:02}") for i in range(24)])
        min_picker = ft.CupertinoPicker(selected_index = m, item_extent = 32, controls = [ft.Text(f"{i:02}") for i in range(60)])
        sec_picker = ft.CupertinoPicker(selected_index = s, item_extent = 32, controls = [ft.Text(f"{i:02}") for i in range(60)])

        #画面上の古いピッカーを、新しく作ったピッカーに差し替える
        picker_row.controls[0].content = hour_picker
        picker_row.controls[2].content = min_picker
        picker_row.controls[4].content = sec_picker


    def set_template_5(e):
        if not is_running:
            set_picker_time(0,5,0)

    def set_template_25(e):
        if not is_running:
            set_picker_time(0,25,0)

    def set_template_60(e):
        if not is_running:
            set_picker_time(1,0,0)

    def set_template_90(e):
        if not is_running:
            set_picker_time(1,30,0)

    #2-3.アクションボタン（BottonクラスとRowクラス）
    #背景が透明のボタン
    cancel_btn = ft.OutlinedButton("キャンセル", width = 120, height = 60, on_click = on_cancel_click)
    #背景が塗りつぶされたボタン
    start_btn = ft.FilledButton("開始", width = 140, height = 60, on_click=on_start_click)

    action_btn_row = ft.Row(
        controls=[cancel_btn, start_btn],
        alignment=ft.MainAxisAlignment.CENTER
    )

    #2-4.テンプレート（プリセット）ボタン
    template_title = ft.Text("テンプレート", size = 18 , weight=ft.FontWeight.BOLD)

    btn_5min = ft.OutlinedButton("ポモドーロ\n5:00", width=150, height=60, on_click=set_template_5)
    btn_25min = ft.OutlinedButton("ポモドーロ\n25:00", width=150, height=60, on_click=set_template_25)
    btn_60min = ft.OutlinedButton("講義１\n1:00:00", width=150, height=60, on_click=set_template_60)
    btn_90min = ft.OutlinedButton("講義２\n1:30:00", width=150, height=60, on_click=set_template_90)

    preset_row1 = ft.Row(controls=[btn_5min, btn_25min], alignment=ft.MainAxisAlignment.CENTER)
    preset_row2 = ft.Row(controls=[btn_60min, btn_90min], alignment=ft.MainAxisAlignment.CENTER)

    #2-5.ナビゲーションバー（NavigationBarクラス）
    page.navigation_bar = ft.NavigationBar(
        destinations=[
            ft.NavigationBarDestination(icon = ft.Icons.TIMER, label = "セット"),
            ft.NavigationBarDestination(icon = ft.Icons.FORMAT_LIST_BULLETED, label = "一覧"),
        ],
        selected_index = 0
    )

    ##ーーー３．コントロールツリーへの追加（画面描画）　ーーー
    page.add(
        ft.Column(
            controls = [
                ft.Row(controls=[title], alignment = ft.MainAxisAlignment.CENTER),
                ft.Divider(height = 5), #区切り線
                timer_title,
                picker_row,
                countdown_display,
                ft.Container(height=10), #縦方向の間隔調整用コンテナ
                action_btn_row,
                ft.Container(height=5),
                ft.Divider(height = 10),
                template_title,
                preset_row1,
                preset_row2,
            ],
            #spacing = 15 #各要素間の垂直方向の余白
        )
    )

ft.run(main)