;;; nhk-program.el --- NHK Program API wrapper for emacs

;; Author: Wataru MIYAGUNI (gonngo _at_ gmail.com)
;; URL: https://github.com/gongo/emacs-nhk-program
;; Keywords: nhk

;; Copyright (c) 2013 Wataru MIYAGUNI
;;
;; MIT License
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:

;; This program is a (API) client for NHk Program API <http://api-portal.nhk.or.jp>

;;; Usage:

;;
;; (require 'nhk-program)
;;

;;; Code:

(eval-when-compile (require 'cl))
(require 'helm)
(require 'json)
(require 'popwin)
(require 'request)
(require 'time-date)
(require 'timezone)
(require 'view)

(defconst nhk-program->-buffer "*NHK Program*")

(defconst nhk-program->-template-selection "\
Current %s \"%s\".

If want to save this, write following:
\(setq nhk-program->%s \"%s\"\)
or
\(setq nhk-program->%s \"%s\"\)")

(defconst nhk-program->-template-program "\
\[%s\]

番組タイトル:
%s%s

ジャンル:
%s

放送日時:
%s 〜 %s")


(defconst nhk-program->api-endpoint "http://api.nhk.or.jp/v1/pg")

(defconst nhk-program->service-list
  '(("ＮＨＫ総合１" . "g1")
    ("ＮＨＫ総合２" . "g2")
    ("ＮＨＫＥテレ１" . "e1")
    ("ＮＨＫＥテレ２" . "e2")
    ("ＮＨＫＥテレ３" . "e3")
    ("ＮＨＫワンセグ２" . "e4")
    ("ＮＨＫＢＳ１" . "s1")
    ("ＮＨＫＢＳ１(１０２ｃｈ)" . "s2")
    ("ＮＨＫＢＳプレミアム" . "s3")
    ("ＮＨＫＢＳプレミアム(１０４ｃｈ)" . "s4")
    ("ＮＨＫラジオ第1" . "r1")
    ("ＮＨＫラジオ第2" . "r2")
    ("ＮＨＫＦＭ" . "r3")
    ("ＮＨＫネットラジオ第1" . "n1")
    ("ＮＨＫネットラジオ第2" . "n2")
    ("ＮＨＫネットラジオＦＭ" . "n3")
    ("テレビ全て" . "tv")
    ("ラジオ全て" . "radio")
    ("ネットラジオ全て" . "netradio"))
  "http://api-portal.nhk.or.jp/doc-request#explain_service")

(defconst nhk-program->area-list
  '(("札幌" . "010")
    ("函館" . "011")
    ("旭川" . "012")
    ("帯広" . "013")
    ("釧路" . "014")
    ("北見" . "015")
    ("室蘭" . "016")
    ("青森" . "020")
    ("盛岡" . "030")
    ("仙台" . "040")
    ("秋田" . "050")
    ("山形" . "060")
    ("福島" . "070")
    ("水戸" . "080")
    ("宇都宮" . "090")
    ("前橋" . "100")
    ("さいたま" . "110")
    ("千葉" . "120")
    ("東京" . "130")
    ("横浜" . "140")
    ("新潟" . "150")
    ("富山" . "160")
    ("金沢" . "170")
    ("福井" . "180")
    ("甲府" . "190")
    ("長野" . "200")
    ("岐阜" . "210")
    ("静岡" . "220")
    ("名古屋" . "230")
    ("津" . "240")
    ("大津" . "250")
    ("京都" . "260")
    ("大阪" . "270")
    ("神戸" . "280")
    ("奈良" . "290")
    ("和歌山" . "300")
    ("鳥取" . "310")
    ("松江" . "320")
    ("岡山" . "330")
    ("広島" . "340")
    ("山口" . "350")
    ("徳島" . "360")
    ("高松" . "370")
    ("松山" . "380")
    ("高知" . "390")
    ("福岡" . "400")
    ("北九州" . "401")
    ("佐賀" . "410")
    ("長崎" . "420")
    ("熊本" . "430")
    ("大分" . "440")
    ("宮崎" . "450")
    ("鹿児島" . "460")
    ("沖縄" . "470"))
  "http://api-portal.nhk.or.jp/doc-request#explain_area")

(defconst nhk-program->genre-list
  '(
    ;; ニュース／報道
    ("定時・総合"                         . "0000")
    ("天気"                               . "0001")
    ("特集・ドキュメント"                 . "0002")
    ("政治・国会"                         . "0003")
    ("経済・市況"                         . "0004")
    ("海外・国際"                         . "0005")
    ("解説"                               . "0006")
    ("討論・会談"                         . "0007")
    ("報道特番"                           . "0008")
    ("ローカル・地域"                     . "0009")
    ("交通"                               . "0010")
    ("ニュース／報道 その他"              . "0015")
    ;; スポーツ
    ("スポーツニュース"                   . "0100")
    ("野球"                               . "0101")
    ("サッカー"                           . "0102")
    ("ゴルフ"                             . "0103")
    ("その他の球技"                       . "0104")
    ("相撲・格闘技"                       . "0105")
    ("オリンピック・国際大会"             . "0106")
    ("マラソン・陸上・水泳"               . "0107")
    ("モータースポーツ"                   . "0108")
    ("マリン・ウィンタースポーツ"         . "0109")
    ("競馬・公営競"                       . "0110")
    ("スポーツ その他"                    . "0115")
    ;; 情報/ワイドショー
    ("芸能・ワイドショー"                 . "0200")
    ("ファッション"                       . "0201")
    ("暮らし・住まい"                     . "0202")
    ("健康・医療"                         . "0203")
    ("ショッピング・通販"                 . "0204")
    ("グルメ・料理"                       . "0205")
    ("イベント"                           . "0206")
    ("番組紹介・お知らせ"                 . "0207")
    ("情報/ワイドショー その他"           . "0215")
    ;; ドラマ
    ("国内ドラマ"                         . "0300")
    ("海外ドラマ"                         . "0301")
    ("時代"                               . "0302")
    ("ドラマ その他"                      . "0315")
    ;; 音楽
    ("国内ロック・ポップス"               . "0400")
    ("海外ロック・ポップス"               . "0401")
    ("クラシック・オペラ"                 . "0402")
    ("ジャズ・フュージョン"               . "0403")
    ("歌謡曲・演歌"                       . "0404")
    ("ライブ・コンサート"                 . "0405")
    ("ランキング・リクエスト"             . "0406")
    ("カラオケ・のど自慢"                 . "0407")
    ("民謡・邦楽"                         . "0408")
    ("童謡・キッズ"                       . "0409")
    ("民族音楽・ワールドミュージック"     . "0410")
    ("音楽 その他"                        . "0315")
    ;; バラエティ
    ("クイズ"                             . "0500")
    ("ゲーム"                             . "0501")
    ("トークバラエティ"                   . "0502")
    ("お笑い・コメディ"                   . "0503")
    ("音楽バラエティ"                     . "0504")
    ("旅バラエティ"                       . "0505")
    ("料理バラエティ"                     . "0506")
    ("バラエティ その他"                  . "0515")
    ;; 映画
    ("洋画"                               . "0600")
    ("邦画"                               . "0601")
    ("アニメ"                             . "0602")
    ("映画 その他"                        . "0615")
    ;; アニメ/特撮
    ("国内アニメ"                         . "0700")
    ("海外アニメ"                         . "0701")
    ("特撮"                               . "0702")
    ("アニメ/特撮 その他"                 . "0715")
    ;; ドキュメンタリー／教養
    ("社会・時事"                         . "0800")
    ("歴史・紀行"                         . "0801")
    ("自然・動物・環境"                   . "0802")
    ("宇宙・科学・医学"                   . "0803")
    ("カルチャー・伝統文化"               . "0804")
    ("文学・文芸"                         . "0805")
    ("スポーツ"                           . "0806")
    ("ドキュメンタリー全般"               . "0807")
    ("インタビュー・討論"                 . "0808")
    ("ドキュメンタリー／教養 その他"      . "0815")
    ;; 劇場/公演
    ("現代劇・新劇"                       . "0900")
    ("ミュージカル"                       . "0901")
    ("ダンス・バレエ"                     . "0902")
    ("落語・演芸"                         . "0903")
    ("歌舞伎・古典"                       . "0904")
    ("劇場/公演 その他"                   . "0915")
    ;; 趣味/教育
    ("旅・釣り・アウトドア"               . "1000")
    ("園芸・ペット・手芸"                 . "1001")
    ("音楽・美術・工芸"                   . "1002")
    ("囲碁・将棋"                         . "1003")
    ("麻雀・パチンコ"                     . "1004")
    ("車・オートバイ"                     . "1005")
    ("コンピュータ・ＴＶゲーム"           . "1006")
    ("会話・語学"                         . "1007")
    ("幼児・小学生"                       . "1008")
    ("中学生・高校生"                     . "1009")
    ("大学生・受験"                       . "1010")
    ("生涯教育・資"                       . "1011")
    ("趣味/教育 その他"                   . "1015")
    ;; 福祉
    ("高齢者"                             . "1100")
    ("障害者"                             . "1101")
    ("社会福祉"                           . "1102")
    ("ボランティア"                       . "1103")
    ("手話"                               . "1104")
    ("文字（字幕）"                       . "1105")
    ("音声解説"                           . "1106")
    ("福祉 その他"                        . "1115")
    ;; 拡張
    ("BS/地上デジタル放送用番組付属情報"  . "1400")
    ("広帯域 CS デジタル放送用拡張"       . "1401")
    ("サーバー型番組付属情報"             . "1403")
    ("IP 放送用番組付属情"                . "1404")
    ;; その他
    ("その他"                             . "1515"))
  "http://www.arib.or.jp/english/html/overview/doc/2-STD-B10v5_1.pdf
付録Ｈ（規定）コンテント記述子におけるジャンル指定")

(defvar nhk-program->api-key nil)
(defvar nhk-program->area nil)
(defvar nhk-program->service nil)

(defun nhk-program->-request-raw (url)
  (request (concat nhk-program->api-endpoint url)
           :params `((key . ,nhk-program->api-key))
           :parser (lambda ()
                     (let ((json-object-type 'plist)
                           (json-array-type 'list))
                       (json-read)))
           :sync t))

(defun nhk-program:-request (url)
  (let (response data)
    (setq response (nhk-program->-request-raw url))
    (setq data (request-response-data response))
    (when (eq (request-response-symbol-status response) 'success)
      data)))

;;
;; Buffer
;;

(defun nhk-program:-display-message (message)
  (with-current-buffer (get-buffer-create nhk-program->-buffer)
    (view-mode-disable)
    (erase-buffer)
    (insert message)
    (view-mode-enable))
  (popwin:popup-buffer nhk-program->-buffer :noselect nil))

;;
;; Date
;;

(defun nhk-program:-iso8601-to-time (date)
  (let* ((vars   (timezone-parse-date date))
         (time   (timezone-parse-time (elt vars 3)))
         (year   (string-to-number (elt vars 0)))
         (month  (string-to-number (elt vars 1)))
         (day    (string-to-number (elt vars 2)))
         (hour   (string-to-number (elt time 0)))
         (minute (string-to-number (elt time 1)))
         (second (string-to-number (elt time 2))))
    (encode-time second minute hour day month year)))

(defun nhk-program:-inspect-iso8601 (date)
  (format-time-string "%Y/%m/%d %T" (nhk-program:-iso8601-to-time date)))

;;
;; NHK Program API
;;

(defun nhk-program:-query:today ()
  (format-time-string "%Y-%m-%d"))

(defun nhk-program:-query:tomorrow ()
  (format-time-string "%Y-%m-%d"
                      (time-add (current-time) (days-to-time 1))))

(defun nhk-program:-query:service (service)
  (setq service (or service nhk-program->service))
  (when (assoc service nhk-program->service-list)
    (setq service (cdr (assoc service nhk-program->service-list))))
  (if (rassoc service nhk-program->service-list)
      service
    (error "Service is wrong or is not set")))

(defun nhk-program:-query:area (area)
  (setq area (or area nhk-program->area))
  (when (assoc area nhk-program->area-list)
    (setq area (cdr (assoc area nhk-program->area-list))))
  (if (rassoc area nhk-program->area-list)
      area
    (error "Area is wrong or is not set")))

(defun* nhk-program:list (&key area service tomorrow? &allow-other-keys)
  (setq area (nhk-program:-query:area area))
  (setq service (nhk-program:-query:service service))
  (let* ((date (if tomorrow? (nhk-program:-query:tomorrow) (nhk-program:-query:today)))
         (url (format "/list/%s/%s/%s.json" area service date))
         (response (nhk-program:-request url)))
    (when response
      (sort
       (loop for (service programs) on (plist-get response :list)
             by 'cddr append programs)
       (lambda (a b)
         (let ((atime (nhk-program:-iso8601-to-time (plist-get a :start_time)))
               (btime (nhk-program:-iso8601-to-time (plist-get b :start_time))))
           (time-less-p atime btime)))))))

(defun* nhk-program:now-on-air (&key area service &allow-other-keys)
  (setq area (nhk-program:-query:area area))
  (setq service (nhk-program:-query:service service))
  (let ((url (format "/now/%s/%s.json" area service))
        response programs)
    (setq response (nhk-program:-request url))
    (when response
      (setq programs (cadr (plist-get response :nowonair_list)))
      (list (plist-get programs :previous)
            (plist-get programs :present)
            (plist-get programs :following)))))

;;
;; Helm configurations
;;

(defun nhk-program:-helm:selection-transformer (items)
  (mapcar (lambda (item)
            (let ((title (format "%s (%s)" (car item) (cdr item)))
                  (value item))
              (cons title value)))
          items))

(defun nhk-program:-helm:response-transformer (items)
  (let ((template "%s 〜 %s\n\[%s\]\n%s"))
    (mapcar (lambda (item)
              (let ((title
                     (format template
                             (nhk-program:-inspect-iso8601 (plist-get item :start_time))
                             (nhk-program:-inspect-iso8601 (plist-get item :end_time))
                             (plist-get (plist-get item :service) :name)
                             (plist-get item :title)))
                    (value item))
                (cons title value)))
            items)))

(defun nhk-program:-helm:action:set-service (item)
  (let ((name (car item))
        (value (cdr item)))
    (setq nhk-program->service value)
    (nhk-program:-display-message
     (format nhk-program->-template-selection
             "service" name "service" value "service" name))))

(defun nhk-program:-helm:action:set-area (item)
  (let ((name (car item))
        (value (cdr item)))
    (setq nhk-program->area value)
    (nhk-program:-display-message
     (format nhk-program->-template-selection
             "area" name "area" value "area" name))))

(defun nhk-program:-helm:action:show-program (item)
  (let ((service (plist-get (plist-get item :service) :name))
        (title (plist-get item :title))
        (subtitle (plist-get item :subtitle))
        (genres (mapconcat (lambda (x)
                             (car (rassoc x nhk-program->genre-list)))
                           (plist-get item :genres)
                           ", "))
        (start-date (nhk-program:-inspect-iso8601 (plist-get item :start_time)))
        (end-date (nhk-program:-inspect-iso8601 (plist-get item :end_time))))
    (setq subtitle (if (and subtitle (> (length subtitle) 0))
                       (concat "\n" subtitle) ""))
    (nhk-program:-display-message
     (format nhk-program->-template-program
             service title subtitle genres start-date end-date))))

(define-helm-type-attribute 'nhk-programs
  `((candidate-transformer nhk-program:-helm:response-transformer)
    (action . (("Show program" . nhk-program:-helm:action:show-program)))
    (multiline)))

(defun nhk-program:-helm (name candidates)
  (when candidates
    (helm :sources `((name . ,name)
                     (candidates . ,candidates)
                     (type . nhk-programs)))))

;;
;; User functions
;;

;;;###autoload
(defun nhk-program:helm:select-area ()
  (interactive)
  (helm :sources
        `((name . "Select area parameter")
          (candidates . ,nhk-program->area-list)
          (candidate-transformer nhk-program:-helm:selection-transformer)
          (action . (("Set area parameter" . nhk-program:-helm:action:set-area))))))

;;;###autoload
(defun nhk-program:helm:select-service ()
  (interactive)
  (helm :sources
        `((name . "Select service parameter")
          (candidates . ,nhk-program->service-list)
          (candidate-transformer nhk-program:-helm:selection-transformer)
          (action . (("Set service parameter" . nhk-program:-helm:action:set-service))))))

;;;###autoload
(defun nhk-program:helm:list (tomorrow?)
  (interactive "P")
  (nhk-program:-helm "Program List" (nhk-program:list :tomorrow? tomorrow?)))

;;;###autoload
(defun nhk-program:helm:now-on-air ()
  (interactive)
  (nhk-program:-helm "Now On Air" (nhk-program:now-on-air)))

(provide 'nhk-program)
