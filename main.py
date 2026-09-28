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

    #ボタンを押したときに実行される関数
    async def countdown():
        nonlocal is_running, remaining_time
        while is_running and remaining_time > 0:
            await asyncio.sleep(1)
            if not is_running:
                break
            remaining_time -= 1
            min_input.value = f"{remaining_time // 60:02}"
            sec_input.value = f"{remaining_time % 60:02}"
            page.update()

        if remaining_time <= 0:
            is_running = False
            min_input.disabled = False
            sec_input.disabled = False

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
        try:
            m = int(min_input.value) if min_input.value else 0
            s = int(sec_input.value) if sec_input.value else 0
            remaining_time = m * 60 + s
        except ValueError:
            return

        if remaining_time > 0:
            is_running = True
            min_input.disabled = True
            sec_input.disabled = True
            page.update()
            await countdown()

    def on_cancel_click(e):
        nonlocal is_running
        is_running = False
        min_input.disabled = False
        sec_input.disabled = False
        page.update()

    def set_template_5(e):
        if not is_running:
            min_input.value = "05"
            sec_input.value = "00"
            page.update()

    def set_template_25(e):
            if not is_running:
                min_input.value = "25"
                sec_input.value = "00"
                page.update()

    def set_template_60(e):
            if not is_running:
                min_input.value = "60"
                sec_input.value = "00"
                page.update()

    def set_template_90(e):
            if not is_running:
                min_input.value = "90"
                sec_input.value = "00"
                page.update()

    

    #ーーー２．UIコントロールのインスタンス化　ーーー
    
    #2-1.タイトル（Textクラス）
    title = ft.Text("無音タイマー", size = 18, weight=ft.FontWeight.NORMAL,color = ft.Colors.GREY_500,font_family="MS Mincho")

    #2-2.時間設定フォーム（TextFieldクラスとRowクラス）
    timer_title = ft.Text("タイマーセット", size = 18 , weight=ft.FontWeight.BOLD)

    min_input = ft.TextField(value = "00", label = "分", width = 100, text_align=ft.TextAlign.CENTER)
    sec_input = ft.TextField(value = "00", label = "秒", width = 100, text_align=ft.TextAlign.CENTER)

    time_setting_row = ft.Row(
        controls = [min_input, ft.Text("分", size = 20), sec_input, ft.Text("秒", size = 20)],
        alignment = ft.MainAxisAlignment.CENTER
    )

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
                ft.Container(height=25),
                timer_title,
                ft.Container(height=10),
                time_setting_row,
                ft.Container(height=10), #縦方向の間隔調整用コンテナ
                action_btn_row,
                ft.Container(height=5),
                ft.Divider(height = 30),
                template_title,
                ft.Container(height=5),
                preset_row1,
                preset_row2,
            ],
            #spacing = 15 #各要素間の垂直方向の余白
        )
    )

ft.run(main)