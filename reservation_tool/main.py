import sys
import json
import logging
from pathlib import Path
from datetime import datetime
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeoutError


################################
# ログ設定
################################
def setup_logging():
    """
    ログファイルを logs/YYYYMMDD.log に作成し、
    コンソールとファイルの両方に出力する。
    """
    # EXE化対応：実行ファイルと同じフォルダにlogsフォルダを作成
    if getattr(sys, 'frozen', False):
        # EXEとして実行されている場合
        application_path = Path(sys.executable).parent
    else:
        # Pythonスクリプトとして実行されている場合
        application_path = Path(__file__).parent
    
    log_dir = application_path / "logs"
    log_dir.mkdir(exist_ok=True)
    
    log_file = log_dir / f"{datetime.now().strftime('%Y%m%d')}.log"
    
    # ログフォーマット
    log_format = "%(asctime)s [%(levelname)s] %(message)s"
    date_format = "%Y-%m-%d %H:%M:%S"
    
    # ルートロガーの設定
    logger = logging.getLogger()
    logger.setLevel(logging.DEBUG)
    
    # 既存のハンドラーをクリア（重複防止）
    logger.handlers.clear()
    
    # ファイルハンドラー
    file_handler = logging.FileHandler(log_file, encoding="utf-8")
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(logging.Formatter(log_format, date_format))
    logger.addHandler(file_handler)
    
    # コンソールハンドラー
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(logging.Formatter(log_format, date_format))
    logger.addHandler(console_handler)
    
    logging.info(f"ログファイル: {log_file}")
    return log_file


################################
# ポップアップ表示ユーティリティ
################################
def popup_info(message: str):
    import tkinter
    from tkinter import messagebox
    root = tkinter.Tk()
    root.withdraw()
    root.attributes('-topmost', True)  # 最前面表示
    root.lift()  # ウィンドウを前面に
    root.focus_force()  # フォーカスを強制
    messagebox.showinfo("予約ツール", message, parent=root)
    root.destroy()


def popup_error(message: str):
    import tkinter
    from tkinter import messagebox
    root = tkinter.Tk()
    root.withdraw()
    root.attributes('-topmost', True)  # 最前面表示
    root.lift()  # ウィンドウを前面に
    root.focus_force()  # フォーカスを強制
    messagebox.showerror("予約ツール - エラー", message, parent=root)
    root.destroy()


################################
# config.json 読み込み
################################
def load_config():
    """
    config.json（例）

    {
      "login": {
        "sisetu_code": "25",
        "dantai_code": "0103",
        "password": "chik1000"
      },
      "reservation": {
        "facility_name": "桜道コミュニティハウス",
        "facility_id": "6",

        "month_value": "2025-11:4",   // <select id="ym"> の value
        "day_label": "01",           // 希望日(表示上の"01","02"...)
        "timeslot_keywords": ["午前", "午後①"],

        // timeslot_keywords が無い場合の後方互換
        // "timeslot_keyword": "午前"
      },
      "run": {
        "wait_until_time": null
      }
    }
    """
    # EXE化対応：実行ファイルと同じフォルダのconfig.jsonを探す
    if getattr(sys, 'frozen', False):
        # EXEとして実行されている場合
        application_path = Path(sys.executable).parent
    else:
        # Pythonスクリプトとして実行されている場合
        application_path = Path(__file__).parent
    
    cfg_path = application_path / "config.json"
    
    try:
        with open(cfg_path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        popup_error(f"config.json が見つかりません。\n\n以下の場所に config.json を配置してください：\n{cfg_path}")
        sys.exit(1)
    except json.JSONDecodeError:
        popup_error("config.json の形式が正しくありません。")
        sys.exit(1)


################################
# 指定時刻まで待機（例: "09:59" など）
################################
def wait_until_target_time(hhmm: str | None):
    """
    指定時刻まで待機する。
    
    対応フォーマット：
    - "09:59" : 今日のHH:MM（既に過ぎている場合は即実行）
    - "2025-11-01 00:00" : 指定日時（未来の日時まで待機）
    None / "" の場合は即実行。
    """
    if not hhmm:
        return
    
    import time
    
    # 日時形式（YYYY-MM-DD HH:MM）かチェック
    if len(hhmm) > 5 and ' ' in hhmm:
        # 日時形式
        try:
            target_datetime = datetime.strptime(hhmm, "%Y-%m-%d %H:%M")
            logging.info(f"⏰ 指定日時 {hhmm} まで待機します...")
            logging.info("💡 Ctrl+C で待機をキャンセルできます")
            
            while True:
                now = datetime.now()
                if now >= target_datetime:
                    logging.info("⏰ 指定時刻になりました。実行を開始します！")
                    break
                
                remaining = target_datetime - now
                # 10秒ごとに残り時間をログ出力
                if remaining.total_seconds() % 10 < 1:
                    hours, remainder = divmod(remaining.total_seconds(), 3600)
                    minutes, seconds = divmod(remainder, 60)
                    logging.debug(f"残り時間: {int(hours):02d}:{int(minutes):02d}:{int(seconds):02d}")
                
                time.sleep(0.5)
        except ValueError:
            logging.error(f"日時フォーマットエラー: {hhmm} (正しい形式: YYYY-MM-DD HH:MM)")
            popup_error(f"wait_until_time の形式が正しくありません\n\n設定値: {hhmm}\n\n正しい形式: 2025-11-01 00:00")
            import sys
            sys.exit(1)
    else:
        # 時刻のみ形式（HH:MM）- 従来の動作
        logging.info(f"⏰ 指定時刻 {hhmm} まで待機します...")
        logging.info("💡 Ctrl+C で待機をキャンセルできます")
        
        while True:
            now = datetime.now().strftime("%H:%M")
            if now >= hhmm:
                logging.info("⏰ 指定時刻になりました。実行を開始します！")
                break
            time.sleep(0.5)


################################
# 1. ログイン
################################
def do_login(page, cfg):
    """
    ログイン画面 -> ログイン完了（直接予約ボタンが見えるところまで）
    """
    login_url = "https://f-supportsys.com/kounan/reserve/login.php"
    page.goto(login_url, timeout=15000)

    page.fill("#login_sisetu_code", cfg["login"]["sisetu_code"])
    page.fill("#login_dantai_code", cfg["login"]["dantai_code"])
    page.fill("#login_pw",          cfg["login"]["password"])

    page.click("#btn_submit")

    # ログイン後、「直接予約」ボタン(#btn_yoyaku)が現れるのを待つ
    page.wait_for_selector("#btn_yoyaku", timeout=10000)


################################
# 2. メニュー → 直接予約
################################
def open_direct_reservation_menu(page):
    """
    メインメニューで「直接予約」(#btn_yoyaku)を押して施設一覧へ
    """
    page.click("#btn_yoyaku")

    # yoyaku_list がURLに含まれるページを待つ
    page.wait_for_url(lambda url: "yoyaku_list" in url, timeout=10000)

    # 施設一覧ロード完了の目印
    page.wait_for_selector("text=地区センター", timeout=10000)
    
    # デバッグ: 施設一覧を表示
    try:
        logging.debug("=== 施設一覧のデバッグ情報 ===")
        all_buttons = page.locator('img[onClick^="$.new_yoyaku"]').all()
        logging.debug(f"予約ボタン総数: {len(all_buttons)}個")
        
        # 各ボタンの情報を取得
        for i, btn in enumerate(all_buttons[:10]):  # 最大10件まで
            try:
                onclick = btn.get_attribute("onClick")
                # 親要素のテキストを取得（施設名が含まれている）
                parent = btn.locator('xpath=ancestor::td[1]').first
                if parent.count() > 0:
                    # さらに親のtr要素から全テキストを取得
                    row = parent.locator('xpath=ancestor::tr[1]').first
                    if row.count() > 0:
                        row_text = row.inner_text().strip().replace('\n', ' ')[:100]
                        logging.debug(f"  [{i+1}] onClick={onclick} | 行テキスト: {row_text}")
            except Exception as e:
                logging.debug(f"  [{i+1}] 情報取得エラー: {e}")
        
        logging.debug("============================")
    except Exception as e:
        logging.debug(f"施設一覧デバッグ中にエラー: {e}")


################################
# 3. 対象施設の「予約する」を押す
################################
def click_facility_and_confirm(page, cfg_reservation):
    """
    施設一覧の中から目的の施設を開く。
    > 優先順位: facility_id → facility_name → エラー（fallbackなし）
    > confirmダイアログが複数回出ても自動で accept（最大5回）。
    > 遷移後のフォーム(#ym, #room_id)が出るまで待つ。
    """

    facility_id = cfg_reservation.get("facility_id")
    facility_name = cfg_reservation.get("facility_name", "")

    logging.info(f"施設選択開始: name='{facility_name}' id={facility_id}")

    # 複数のダイアログに対応（最大5回まで自動accept）
    dialog_count = [0]
    def handle_dialog(dialog):
        dialog_count[0] += 1
        logging.debug(f"facility selection dialog #{dialog_count[0]}: {dialog.message}")
        dialog.accept()
    
    page.on("dialog", handle_dialog)

    clicked = False
    selected_method = ""
    
    # 【優先1】施設IDで検索（最も確実）
    if facility_id:
        try:
            logging.debug(f"[方法1] facility_id={facility_id} で検索中...")
            target_btn = page.locator(
                f'img[onClick^="$.new_yoyaku({facility_id},"]'
            ).first
            count = target_btn.count()
            logging.debug(f"  → 見つかったボタン数: {count}")
            
            if count > 0:
                logging.info(f"✅ 施設ID {facility_id} でボタンを発見")
                target_btn.click()
                clicked = True
                selected_method = f"facility_id={facility_id}"
            else:
                logging.warning(f"⚠️ 施設ID {facility_id} のボタンが見つかりません")
        except Exception as e:
            logging.warning(f"施設ID検索でエラー: {e}")
    
    # 【優先2】施設名で検索
    if not clicked and facility_name:
        try:
            logging.debug(f"[方法2] facility_name='{facility_name}' で検索中...")
            
            # より柔軟な検索: ページ内の全てのテキストから施設名を探す
            # 方法A: td要素から直接探す
            facility_cells = page.locator(f'td:has-text("{facility_name}")').all()
            logging.debug(f"  → 施設名を含むtd要素: {len(facility_cells)}個")
            
            if len(facility_cells) > 0:
                # 施設名が見つかった場合、その行の予約ボタンを探す
                for cell in facility_cells:
                    # 親要素（tr）を取得して、その中の予約ボタンを探す
                    try:
                        parent_row = cell.locator('xpath=ancestor::tr[1]').first
                        if parent_row.count() > 0:
                            btn = parent_row.locator('img[onClick^="$.new_yoyaku"]').first
                            if btn.count() > 0:
                                logging.info(f"✅ 施設名 '{facility_name}' でボタンを発見")
                                btn.click()
                                clicked = True
                                selected_method = f"facility_name='{facility_name}'"
                                break
                    except Exception as e:
                        logging.debug(f"  行の解析でエラー: {e}")
                        continue
            
            if not clicked:
                logging.warning(f"⚠️ 施設名 '{facility_name}' のボタンが見つかりません")
        except Exception as e:
            logging.warning(f"施設名検索でエラー: {e}")
    
    # 【fallback削除】間違った施設を選択するよりエラーにする
    if not clicked:
        page.remove_listener("dialog", handle_dialog)
        error_msg = (
            f"❌ 施設が見つかりませんでした\n\n"
            f"設定: facility_name='{facility_name}', facility_id={facility_id}\n\n"
            f"以下を確認してください：\n"
            f"1. config.json の facility_name と facility_id が正しいか\n"
            f"2. ログイン後の施設一覧に該当施設が表示されているか\n"
            f"3. 施設名の表記が完全に一致しているか（スペースなど）"
        )
        logging.error(error_msg)
        popup_error(error_msg)
        raise Exception("施設選択に失敗しました")

    logging.info(f"施設ボタンをクリック（選択方法: {selected_method}）")

    # 遷移後のフォームが安定するのを待つ
    try:
        page.wait_for_load_state("networkidle", timeout=10000)
        page.wait_for_selector("select#ym", timeout=10000)
        page.wait_for_selector("select#room_id", timeout=10000)
        
        # 遷移後の施設名を確認（検証）
        try:
            page_title = page.locator(".text_26p").first.inner_text().strip()
            logging.info(f"📍 遷移先の施設: 「{page_title}」")
            
            if facility_name and facility_name not in page_title:
                logging.warning(
                    f"⚠️ 警告: 設定した施設名 '{facility_name}' と "
                    f"実際の施設 '{page_title}' が一致しません"
                )
        except Exception as e:
            logging.debug(f"施設名確認でエラー: {e}")
        
        logging.info("✅ 予約フォーム表示完了")
    finally:
        # ダイアログリスナーを解除
        page.remove_listener("dialog", handle_dialog)


################################
# 4. 月 / 部屋 / 日付 / 時間帯 を入力
################################
def fill_form_all(page, cfg):
    """
    ステップ順で確実に埋める:
      1. 利用希望月 (#ym)
      2. 使用希望の部屋 (#room_id) → 「多目的室」を選択する
      3. (#ym/#room_id 選択後にJSが走るので待つ)
      4. 利用希望日 (#hi) を選ぶ
      5. 時間帯 (#times) を、configの優先リストに従ってクリック
      6. サイト側JSが後で勝手にリセットしても、最大3回まで日付/時間帯を再セット

    ここまで終われば、オレンジの「この条件で予約」ボタンを押せる手前の状態になる。
    """

    reservation_cfg = cfg["reservation"]
    month_value      = reservation_cfg.get("month_value")           # "2025-11:4" など
    desired_day_text = reservation_cfg.get("day_label", "")         # "01" など
    # 時間帯は複数優先候補（例 ["午前","午後①"]）にも単一文字列にも対応
    if "timeslot_keywords" in reservation_cfg:
        timeslot_priority = reservation_cfg["timeslot_keywords"]
    elif "timeslot_keyword" in reservation_cfg:
        timeslot_priority = [reservation_cfg["timeslot_keyword"]]
    else:
        timeslot_priority = []

    # 高速モードの検出
    fast_mode = getattr(page, '_fast_mode', False)
    
    # 待機時間の設定（高速モードで短縮）
    short_wait = 50 if fast_mode else 200    # 通常200ms → 50ms
    medium_wait = 150 if fast_mode else 300  # 通常300ms → 150ms
    long_wait = 300 if fast_mode else 500    # 通常500ms → 300ms
    js_wait = 400 if fast_mode else 800      # 通常800ms → 400ms

    logging.debug("fill_form_all start")
    logging.debug(f"month_value={month_value}, day_label={desired_day_text}, timeslot_priority={timeslot_priority}")
    if fast_mode:
        logging.debug("⚡ 高速モードで実行中")

    # --- ヘルパー: 月(#ym)を選ぶ
    def pick_month():
        if not month_value:
            return False
        try:
            page.wait_for_selector("select#ym", timeout=3000)
            page.select_option("select#ym", value=month_value)
            page.wait_for_timeout(short_wait)
            return True
        except Exception as e:
            logging.warning(f"pick_month failed: {e}")
            return False

    def month_is_set():
        try:
            val = page.eval_on_selector("select#ym", "el => el && el.value")
        except Exception:
            return False
        if not val or val == "0":
            return False
        return (not month_value) or (val == month_value)

    # --- ヘルパー: 部屋(#room_id)を「多目的室」にする
    def pick_room_mokuteki():
        try:
            page.wait_for_selector("select#room_id", timeout=3000)
        except Exception as e:
            logging.warning(f"room_id select not found: {e}")
            return False

        try:
            opts = page.locator("select#room_id option")
            count = opts.count()
            
            # デバッグ: 利用可能な部屋一覧を表示
            available_rooms = []
            for i in range(count):
                o = opts.nth(i)
                label = o.inner_text().strip()
                val   = o.get_attribute("value")
                if val and not val.startswith("0"):
                    available_rooms.append(label)
            
            if available_rooms:
                logging.debug(f"利用可能な部屋: {', '.join(available_rooms)}")
            
            # 多目的室を探す
            for i in range(count):
                o = opts.nth(i)
                label = o.inner_text().strip()
                val   = o.get_attribute("value")
                if not val or val.startswith("0"):
                    continue
                if "多目的" in label:
                    logging.info(f"✅ 部屋を選択: '{label}' (value={val})")
                    page.select_option("select#room_id", value=val)
                    page.wait_for_timeout(short_wait)
                    return True
            
            # 多目的室が見つからなかった
            logging.error(f"❌ '多目的室' が見つかりません。利用可能な部屋: {', '.join(available_rooms)}")
            popup_error(
                f"部屋選択エラー\n\n"
                f"'多目的室' が見つかりませんでした。\n\n"
                f"利用可能な部屋:\n" + "\n".join([f"  - {r}" for r in available_rooms]) + "\n\n"
                f"【考えられる原因】\n"
                f"・間違った施設が選択されている\n"
                f"・設定ファイルの facility_name または facility_id が間違っている"
            )
            return False
        except Exception as e:
            logging.warning(f"pick_room_mokuteki failed: {e}")
            return False

    def room_is_mokuteki():
        try:
            label = page.eval_on_selector(
                "select#room_id",
                "sel => sel.options[sel.selectedIndex]?.textContent.trim()"
            )
        except Exception:
            return False
        if not label:
            return False
        return "多目的" in label  # "多目的室" 含んでいればOK

    # 1. 月と部屋を安定して選ぶ（JSが何度も再描画するので最大5回トライ）
    max_retries = 3 if fast_mode else 5  # 高速モードではリトライ回数を削減
    for attempt in range(max_retries):
        if not month_is_set():
            pick_month()

        page.wait_for_timeout(medium_wait)

        if not room_is_mokuteki():
            pick_room_mokuteki()

        page.wait_for_timeout(long_wait)

        if month_is_set() and room_is_mokuteki():
            logging.debug("month & room look stable ✅")
            break
        else:
            logging.debug("retry month/room selection...")

    # JS($.disp_eb_r) が #hi と #times を生成するので少し待つ
    page.wait_for_timeout(js_wait)

    # --- ヘルパー: 日付 (#hi) を選ぶ
    def pick_day_preferred_or_first():
        """
        第一希望 desired_day_text ("01"など)が選べればそれ。
        無理なら最初に現れる有効な日。
        成功したらその option.value (例 "1:1") を返す。
        """
        try:
            page.wait_for_selector("select#hi", timeout=3000)
        except Exception as e:
            logging.warning(f"#hi not found: {e}")
            return None

        chosen_val = None
        fallback   = None
        available_days = []  # 利用可能な日付リスト

        try:
            opts = page.locator("select#hi option")
            count = opts.count()
            for i in range(count):
                o = opts.nth(i)
                disp = o.inner_text().strip()      # "01","02",...
                val  = o.get_attribute("value")    # "1:1","2:1",...
                if (not val) or val == "0" or "選択して下さい" in disp:
                    continue

                # 利用可能な日付リストに追加
                available_days.append(disp)

                # 希望日に一致？
                if desired_day_text and (
                    disp == desired_day_text or
                    disp.lstrip("0") == desired_day_text.lstrip("0")
                ):
                    chosen_val = val
                    break

                # fallbackをまだ記録してないなら覚える
                if fallback is None:
                    fallback = val
            
            # 利用可能な日付をログに表示
            if available_days:
                logging.debug(f"利用可能な日付: {', '.join(available_days[:10])}")  # 最大10個

            final_val = chosen_val if chosen_val else fallback
            if final_val:
                if chosen_val:
                    logging.info(f"✅ 希望日 '{desired_day_text}' を選択（value={final_val}）")
                else:
                    logging.warning(f"⚠️ 希望日 '{desired_day_text}' が見つかりません。最初の有効日を選択（value={fallback}）")
                
                page.select_option("select#hi", value=final_val)
                page.wait_for_timeout(short_wait)
                
                # 選択後の確認
                selected_text = page.eval_on_selector(
                    "select#hi",
                    "sel => sel.options[sel.selectedIndex]?.textContent.trim()"
                )
                logging.info(f"📅 選択された日付: {selected_text}")
                
                return final_val
        except Exception as e:
            logging.warning(f"pick_day_preferred_or_first failed: {e}")

        return None

    chosen_day_val = pick_day_preferred_or_first()

    # --- ヘルパー: 時間帯 (#times) を優先リストで選ぶ
    def pick_timeslot_priority():
        """
        timeslot_priority = ["午前","午後①","午後②",...]
        という優先順で、#times 内の label を走査。
        リストにある全ての時間帯をチェックする。
        チェックできた数を返す。
        """
        if not timeslot_priority:
            logging.debug("no timeslot_priority configured")
            return 0

        try:
            page.wait_for_selector("#times", timeout=3000)
        except Exception as e:
            logging.warning(f"#times not found: {e}")
            return 0

        checked_count = 0
        try:
            labels = page.locator("#times label")
            n = labels.count()
            
            # 各希望時間帯に対してチェックを試みる
            for want in timeslot_priority:
                logging.debug(f"trying timeslot '{want}'")
                found = False
                
                for i in range(n):
                    lab = labels.nth(i)
                    txt = lab.inner_text().strip()
                    if want in txt:
                        found = True
                        # チェックボックスの現在の状態を確認
                        inp = lab.locator("input")
                        if inp.count() > 0:
                            is_already_checked = inp.first.is_checked()
                            if not is_already_checked:
                                # まだチェックされていない場合のみクリック
                                lab.click()
                                page.wait_for_timeout(short_wait)
                                # チェック確認
                                if inp.first.is_checked():
                                    logging.info(f"✅ 時間帯をチェック: '{txt}'")
                                    checked_count += 1
                                else:
                                    logging.warning(f"⚠️ '{txt}' のチェックに失敗")
                            else:
                                # すでにチェック済み
                                logging.debug(f"'{txt}' は既にチェック済み")
                                checked_count += 1
                        break  # この時間帯は見つかったので次へ
                
                if not found:
                    logging.warning(f"⚠️ 時間帯 '{want}' が見つかりません")
            
            if checked_count > 0:
                logging.info(f"✅ 合計 {checked_count} 個の時間帯をチェックしました")
                
                # 実際にチェックされている時間帯を確認
                try:
                    checked_labels = page.locator("#times input:checked").all()
                    checked_names = []
                    for inp in checked_labels:
                        parent_label = inp.locator("xpath=..").first
                        if parent_label.count() > 0:
                            label_text = parent_label.inner_text().strip()
                            checked_names.append(label_text)
                    
                    if checked_names:
                        logging.info(f"📋 チェック済み時間帯: {', '.join(checked_names)}")
                except Exception as e:
                    logging.debug(f"チェック済み時間帯の確認でエラー: {e}")
                
                return checked_count
            else:
                logging.warning("どの時間帯もチェックできませんでした")
                return 0
        except Exception as e:
            logging.warning(f"pick_timeslot_priority failed: {e}")
            return 0

    times_ok = pick_timeslot_priority()

    # --- リセット対策：サイト側JSがあとから値を吹き飛ばすことがあるので復帰を試みる
    def day_is_still_selected():
        if not chosen_day_val:
            return False
        try:
            cur = page.eval_on_selector("select#hi", "el => el && el.value")
        except Exception:
            return False
        return cur == chosen_day_val

    def timeslot_is_still_checked():
        """選択されているべき時間帯の数をカウント"""
        try:
            checked = page.locator("#times input:checked")
            count = checked.count()
            # timeslot_priorityで指定した数と一致するか確認
            expected_count = len(timeslot_priority) if timeslot_priority else 0
            return count >= expected_count
        except Exception:
            return False

    def get_checked_timeslot_count():
        """現在チェックされている時間帯の数を返す"""
        try:
            checked = page.locator("#times input:checked")
            return checked.count()
        except Exception:
            return 0

    # リセット対策：サイト側JSが値を吹き飛ばした場合に再設定
    verify_retries = 2 if fast_mode else 3  # 高速モードでは検証回数を削減
    for attempt in range(verify_retries):
        page.wait_for_timeout(long_wait)

        ok_day  = day_is_still_selected()
        ok_time = timeslot_is_still_checked()
        current_checked = get_checked_timeslot_count()

        logging.debug(f"verify loop #{attempt+1}: ok_day={ok_day}, checked_timeslots={current_checked}/{len(timeslot_priority)}")

        if ok_day and ok_time:
            break

        if (not ok_day) and chosen_day_val:
            # 日付が消えたら選び直す
            try:
                page.select_option("select#hi", value=chosen_day_val)
                page.wait_for_timeout(short_wait)
                logging.debug("reselected day after reset")
            except Exception as e:
                logging.warning(f"failed to reselect day: {e}")

        if (not ok_time) and timeslot_priority:
            # 時間帯が外れてたらもう一度
            logging.debug(f"re-checking timeslots (currently {current_checked} checked)")
            pick_timeslot_priority()

    # 最終確認：実際に選択された内容をログに出力
    try:
        final_month = page.eval_on_selector("select#ym", "sel => sel.options[sel.selectedIndex]?.textContent.trim()")
        final_room = page.eval_on_selector("select#room_id", "sel => sel.options[sel.selectedIndex]?.textContent.trim()")
        final_day = page.eval_on_selector("select#hi", "sel => sel.options[sel.selectedIndex]?.textContent.trim()")
        
        final_times = []
        try:
            checked_inputs = page.locator("#times input:checked").all()
            for inp in checked_inputs:
                parent = inp.locator("xpath=..").first
                if parent.count() > 0:
                    final_times.append(parent.inner_text().strip())
        except:
            pass
        
        logging.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        logging.info("📋 最終選択内容:")
        logging.info(f"  月: {final_month}")
        logging.info(f"  部屋: {final_room}")
        logging.info(f"  日: {final_day}")
        logging.info(f"  時間帯: {', '.join(final_times) if final_times else '未選択'}")
        logging.info("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    except Exception as e:
        logging.debug(f"最終確認でエラー: {e}")

    logging.info("fill_form_all done")


################################
# 5. オレンジボタンを押して、アラートOKして、ユーザーに引き渡し
################################
def press_orange_and_notify(page):
    """
    ・「この条件で予約（予約確認画面へ）」ボタン(#btn_next)をクリック
    ・もしalert/confirmダイアログが出たらOK（複数回対応）
    ・ダイアログメッセージを記録してユーザーに通知
    ・画面遷移やエラーメッセージを検出してユーザーに通知
    """
    # 複数のダイアログに対応（最大5回まで自動accept）
    dialog_count = [0]
    dialog_messages = []  # ダイアログメッセージを保存
    
    def handle_dialog(dialog):
        dialog_count[0] += 1
        msg = dialog.message
        dialog_type = dialog.type
        logging.info(f"ダイアログ #{dialog_count[0]} ({dialog_type}): {msg}")
        dialog_messages.append({"type": dialog_type, "message": msg})
        dialog.accept()
    
    page.on("dialog", handle_dialog)

    clicked = False
    current_url = page.url
    
    try:
        page.wait_for_selector("#btn_next", timeout=3000)
        page.click("#btn_next")
        clicked = True
        logging.info("clicked #btn_next")
    except Exception as e:
        logging.warning(f"could not click #btn_next: {e}")
        page.remove_listener("dialog", handle_dialog)
        popup_info(
            "月・部屋・日付・時間帯まで自動入力しました。\n"
            "画面のオレンジ色『この条件で予約』ボタンを押して、確認画面へ進んでください。\n\n"
            "※このメッセージを閉じてもブラウザは開いたままです。"
        )
        return

    # 画面遷移を待つ（最大5秒）
    page.wait_for_timeout(2000)
    
    # ダイアログリスナーを解除
    page.remove_listener("dialog", handle_dialog)
    
    # 画面遷移したかどうかをチェック
    new_url = page.url
    url_changed = (current_url != new_url)
    
    # エラーメッセージ（時間外・満席など）を検出
    error_messages = []
    
    try:
        # よくあるエラーメッセージパターンを検索
        error_patterns = [
            "予約受付時間外",
            "時間外",
            "満室",
            "予約できません",
            "選択できません",
            "申し訳ございません",
            "エラー"
        ]
        
        for pattern in error_patterns:
            error_elems = page.locator(f"text={pattern}").all()
            if len(error_elems) > 0:
                for elem in error_elems[:2]:  # 最大2件まで
                    try:
                        text = elem.inner_text().strip()
                        if text and len(text) < 200:  # 長すぎるテキストは除外
                            error_messages.append(text)
                    except:
                        pass
    except Exception as e:
        logging.debug(f"error message detection failed: {e}")
    
    # ダイアログメッセージをユーザーに通知
    dialog_notification = ""
    if dialog_messages:
        logging.info(f"合計 {len(dialog_messages)} 個のダイアログが表示されました")
        important_messages = []
        for d in dialog_messages:
            msg = d["message"]
            # 重要なキーワードを含むメッセージを抽出
            if any(keyword in msg for keyword in [
                "時間外", "受付時間", "予約できません", "満室", "エラー", 
                "できません", "不可", "休館", "利用できません"
            ]):
                important_messages.append(msg)
        
        if important_messages:
            dialog_notification = "\n\n【システムメッセージ】\n" + "\n".join(set(important_messages))
    
    # 確認画面に遷移したかチェック（複数の方法で判定）
    reached_confirmation = False
    
    # 方法1: URL変化をチェック
    if url_changed:
        reached_confirmation = True
        logging.info("URL変化を検出：確認画面に遷移しました")
    
    # 方法2: URLに"conf"が含まれるか（yoyaku_conf.phpなど）
    try:
        current_url_lower = page.url.lower()
        if "conf" in current_url_lower or "kakunin" in current_url_lower:
            reached_confirmation = True
            logging.info(f"確認画面のURL検出: {page.url}")
    except:
        pass
    
    # 方法3: 確認画面の特徴的な要素をチェック
    try:
        # 「利用料金合計」「予約を確定する」などの要素
        confirmation_keywords = ["利用料金合計", "予約を確定", "確定する", "利用時間帯"]
        for keyword in confirmation_keywords:
            if page.locator(f"text={keyword}").count() > 0:
                reached_confirmation = True
                logging.info(f"確認画面の要素を検出: '{keyword}'")
                break
    except:
        pass
    
    # ユーザーへの案内
    if reached_confirmation:
        # 画面遷移成功 - ダイアログがあっても成功扱い
        # ポップアップはメインループで表示するため、ここでは表示しない
        logging.info("✅ 確認画面に到達しました")
        
        if dialog_notification:
            logging.info(f"サイトメッセージ: {dialog_notification}")
        
        return "success"  # 成功フラグを返す（ポップアップはメインで表示）
    elif dialog_messages and not error_messages:
        # ダイアログのみ（エラーメッセージなし）の場合は情報として扱う
        dialog_text = "\n".join([d["message"] for d in dialog_messages])
        
        logging.info("サイトからの情報ダイアログ:")
        logging.info(dialog_text)
        
        popup_info(
            f"ℹ️ 予約システムからの情報\n\n"
            f"{dialog_text}\n\n"
            "【次のステップ】\n"
            "・別の日付や時間帯を試してください\n"
            "・サイトの「予約状況表」で空き状況を確認してください\n\n"
            "このメッセージを閉じるとツールが終了します。"
        )
        
        logging.info("情報ダイアログのため、正常終了します")
        # ブラウザを閉じる
        return "info_only"  # 情報のみ（正常終了）
    elif error_messages or dialog_messages:
        # エラーメッセージまたはダイアログが検出された
        error_parts = []
        
        if error_messages:
            error_text = "\n".join(set(error_messages))
            error_parts.append(f"【画面上のメッセージ】\n{error_text}")
        
        if dialog_messages:
            dialog_text = "\n".join([d["message"] for d in dialog_messages])
            error_parts.append(f"【ダイアログメッセージ】\n{dialog_text}")
        
        combined_errors = "\n\n".join(error_parts)
        
        logging.warning("エラーが検出されました")
        logging.info(combined_errors)
        
        popup_error(
            f"⚠️ 予約ボタンを押しましたが、以下のメッセージが表示されました：\n\n"
            f"{combined_errors}\n\n"
            "【考えられる原因】\n"
            "・予約受付時間外（予約開始前または受付終了後）\n"
            "・希望日時が満室または予約不可\n"
            "・施設の予約ルールに該当しない（利用上限到達など）\n\n"
            "【対処方法】\n"
            "・予約開始時刻になってから再実行してください\n"
            "・別の日付や時間帯に変更して再実行してください\n\n"
            "このメッセージを閉じるとブラウザが自動的に終了します。"
        )
        
        logging.info("エラーのため、ブラウザを終了します")
        # ブラウザを閉じる
        return "error_detected"  # エラーフラグを返す
    else:
        # 画面遷移もエラーもダイアログも検出されなかった
        popup_info(
            "自動で『この条件で予約』ボタンを押しました。\n"
            "もし確認画面に進んでいれば、内容をチェックして確定してください。\n\n"
            "進んでいない場合は、画面上のメッセージ等を確認して手動で確定を進めてください。\n"
            "（時間外の場合や、希望日時が予約できない場合があります）\n\n"
            "※このメッセージを閉じてもブラウザは開いたままです。"
        )
        return "unknown"  # 不明な状態


################################
# main
################################
def check_and_install_browser():
    """
    Playwrightブラウザがインストールされているか確認
    （EXE版では自動インストール不可のため、エラー案内のみ）
    """
    try:
        # Playwrightのブラウザパスを確認
        from playwright.sync_api import sync_playwright
        pw = sync_playwright().start()
        try:
            browser = pw.chromium.launch(headless=True)
            browser.close()
            pw.stop()
            logging.info("ブラウザは既にインストールされています")
            return True
        except Exception as e:
            pw.stop()
            logging.error(f"ブラウザがインストールされていません: {e}")
            
            # 同梱ブラウザ前提：環境変数 PLAYWRIGHT_BROWSERS_PATH が設定されているか、フォルダが存在するかを案内
            popup_error(
                "❌ Playwright のブラウザが見つかりません\n\n"
                "【確認してください】\n"
                "・配布フォルダ内に 'ms-playwright' フォルダがあること\n"
                "・必ず 'run.bat'（または run.ps1）から起動すること\n\n"
                "【対処方法】\n"
                "・配布物を展開し直し、フォルダ構成を崩さずに実行してください\n"
                "・解決しない場合はログを添えてマッキーに質問してください"
            )
            return False
    except Exception as e:
        logging.error(f"ブラウザチェックでエラー: {e}")
        # チェック自体が失敗した場合は続行を試みる
        return True


def main():
    # ログ初期化
    setup_logging()
    
    cfg = load_config()
    logging.info("設定ファイル読み込み完了")
    logging.info(f"施設: {cfg['reservation'].get('facility_name', 'N/A')}")
    logging.info(f"希望月: {cfg['reservation'].get('month_value', 'N/A')}")
    logging.info(f"希望日: {cfg['reservation'].get('day_label', 'N/A')}")
    logging.info(f"時間帯: {cfg['reservation'].get('timeslot_keywords', [])}")
    
    # 待機時間の表示
    wait_time = cfg["run"].get("wait_until_time")
    if wait_time:
        logging.info(f"待機時間: {wait_time}")
    else:
        logging.info("待機時間: すぐ実行します。")
    
    # ブラウザの確認とインストール
    if not check_and_install_browser():
        logging.error("ブラウザのセットアップに失敗したため終了します")
        sys.exit(1)
    
    # 正常終了フラグ
    success = False

    # パフォーマンス設定
    fast_mode = cfg["run"].get("fast_mode", False)
    headless = cfg["run"].get("headless", False)
    
    if fast_mode:
        logging.info("⚡ 高速モード: 有効")
    if headless:
        logging.info("🔇 ヘッドレスモード: 有効")

    # 指定の解禁時刻があればそこまで待機
    wait_time = cfg["run"]["wait_until_time"]
    if wait_time:
        logging.info(f"⏰ 指定時刻 {wait_time} まで待機します...")
        logging.info("💡 Ctrl+C で待機をキャンセルできます")
    wait_until_target_time(wait_time)

    playwright = None
    browser = None

    try:
        playwright = sync_playwright().start()
        
        # ブラウザ起動オプション
        launch_options = {
            "headless": headless,
        }
        
        # 高速モードの場合、追加の最適化
        if fast_mode:
            launch_options["args"] = [
                "--disable-blink-features=AutomationControlled",  # 自動化検出回避
            ]
        
        browser = playwright.chromium.launch(**launch_options)
        
        # コンテキスト作成（高速モードで最適化）
        context_options = {}
        if fast_mode:
            # 不要なリソース読み込みをスキップ
            context_options = {
                "viewport": {"width": 1280, "height": 720},
            }
        
        context = browser.new_context(**context_options) if context_options else browser.new_context()
        page = context.new_page()
        
        # グローバル変数として fast_mode をページに保存（他の関数から参照可能にする）
        page._fast_mode = fast_mode

        # ログイン → 直接予約メニュー → 対象施設へ
        do_login(page, cfg)
        open_direct_reservation_menu(page)
        click_facility_and_confirm(page, cfg["reservation"])

        # 月・部屋（多目的室）・日付・時間帯まで自動入力
        fill_form_all(page, cfg)

        # オレンジの「この条件で予約」ボタンも押す（ダイアログは自動OK）
        result = press_orange_and_notify(page)

        # 結果に応じて処理を分岐
        if result == "error_detected":
            logging.info("エラーが検出されたため、処理を終了します")
            # ブラウザは自動的に閉じられる（finally節で）
            # 明示的に失敗として終了（run.ps1でエラー判定される）
            success = False
            # finally節でクリーンアップしてから終了
        elif result == "info_only":
            # サイトからの情報ダイアログのみ（予約不可など）
            # エラーではないので正常終了
            logging.info("サイトからの情報を表示しました（正常終了）")
            success = True
            # ブラウザは閉じる（finally節で）
        else:
            # 正常に確認画面まで到達、またはユーザー操作待ち
            success = True

        # ---- ここから先は人間の操作時間（正常時のみ） ----
        if success and result != "info_only":
            # 確認画面に到達した場合は、ポップアップで通知
            logging.info("ブラウザは開いたままです。内容を確認して予約を完了してください。")
            logging.info("ポップアップ表示を試みます...")
            
            # ユーザーに通知（タイムアウト付き）
            popup_success = False
            try:
                import threading
                def show_popup():
                    try:
                        popup_info(
                            "✅ 予約処理が完了しました！\n\n"
                            "【次の手順】\n"
                            "1. ブラウザで予約内容を確認\n"
                            "2. 「予約を確定する」ボタンを押す\n"
                            "3. 予約完了後、ブラウザを閉じる\n\n"
                            "⚠️ ブラウザを閉じると、\n"
                            "   ツールとコンソールも自動的に終了します\n\n"
                            "※このメッセージを閉じてもブラウザは開いたままです"
                        )
                    except Exception as e:
                        logging.error(f"ポップアップ内でエラー: {e}")
                
                popup_thread = threading.Thread(target=show_popup, daemon=True)
                popup_thread.start()
                popup_thread.join(timeout=30)  # 最大30秒待機
                
                if popup_thread.is_alive():
                    logging.warning("ポップアップ表示がタイムアウトしました（30秒）")
                else:
                    logging.info("ポップアップを正常に表示しました")
                    popup_success = True
            except Exception as e:
                logging.error(f"ポップアップ表示でエラー: {e}")
            
            if popup_success:
                logging.info("ポップアップを閉じました")
            
            # ブラウザを開いたままにするため、run.ps1からの終了指示を待つ
            # （Pythonプロセスを終了させるとブラウザも閉じるため）
            logging.info("ブラウザを開いたまま維持します。ユーザーの操作完了を待機中...")
            
            import time as _time
            # 無限ループで待機（run.ps1がプロセスをKillするまで）
            try:
                while True:
                    _time.sleep(1)
            except KeyboardInterrupt:
                logging.info("Ctrl+Cで中断されました")
            except Exception as e:
                logging.info(f"待機中に例外: {type(e).__name__}")

    except PlaywrightTimeoutError:
        # タイムアウト時
        success = False
        logging.error("タイムアウトしました")
        popup_error(
            "タイムアウトしました。画面の読み込みが遅いか、サイト側の構成が変わった可能性があります。"
        )
        if browser is not None:
            auto_close = cfg.get("run", {}).get("auto_close", False)
            if not auto_close:
                popup_info(
                    "タイムアウトしましたが、ブラウザは開いたままです。\n"
                    "今の画面から手動で続けることができます。\n\n"
                    "このメッセージを閉じるとツールが終了します。"
                )
                # input()は使わない（EXE版で動作しないため）

    except Exception as e:
        # 予期しないエラー時
        success = False
        logging.exception(f"予期しないエラーが発生しました: {e}")
        popup_error(f"エラーが発生しました:\n{e}")
        if browser is not None:
            auto_close = cfg.get("run", {}).get("auto_close", False)
            if not auto_close:
                popup_info(
                    "エラーが発生しましたが、ブラウザは開いたままです。\n"
                    "希望日や時間帯を手動で調整して、そのまま予約を進められます。\n\n"
                    "このメッセージを閉じるとツールが終了します。"
                )
                # input()は使わない（EXE版で動作しないため）

    finally:
        # Playwright後片付け
        # success=True の場合はブラウザを開いたままにする
        if not success:
            # エラー時のみブラウザを閉じる
            try:
                if 'context' in locals() and context is not None:
                    context.close()
            except Exception:
                pass
            try:
                if browser is not None:
                    browser.close()
            except Exception:
                pass
            try:
                if playwright is not None:
                    playwright.stop()
            except Exception:
                pass
            logging.info("ツールを終了しました（ブラウザを閉じました）")
        else:
            # 成功時はブラウザを開いたまま（Playwright接続は切断）
            try:
                # contextとplaywrightを切り離す（ブラウザは開いたまま）
                if 'context' in locals() and context is not None:
                    # contextは閉じない（ブラウザが閉じてしまうため）
                    pass
                if playwright is not None:
                    # playwrightは停止しない（ブラウザが閉じてしまうため）
                    pass
            except Exception:
                pass
            logging.info("ツールを終了しました（ブラウザは開いたまま）")
    
    # 明示的な終了コードを返す
    if success:
        logging.info("正常終了 (exit code: 0)")
        sys.exit(0)
    else:
        logging.info("エラー終了 (exit code: 1)")
        sys.exit(1)


if __name__ == "__main__":
    main()
