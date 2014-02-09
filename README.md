NHK Program for Emacs
=====================

Requirement
-----------

* Emacs 24.3 (I check only in this version.)
* [helm](https://github.com/emacs-helm/helm)
* [request](https://github.com/tkf/emacs-request)
* [popwin](https://github.com/m2ym/popwin-el)

Usage
-----

### Configuration

```lisp
(setq nhk-program->api-key "YOUR_API_KEY")
(setq nhk-program->service "テレビ全て") ;; or (setq nhk-program->service "tv")
(setq nhk-program->area "沖縄")          ;; or (setq nhk-program->area "470")
```

### User functions

```lisp
;; Get program list
(nhk-program:list :area "470" :service "tv")

;;; another key
;;; (nhk-program:list :area "沖縄" :service "テレビ全て")

;;; tomorrow list
;;; (nhk-program:list :area "470" :service "tv" :tomorrow? t)

;; Get "Now On Air" list
(nhk-program:now-on-air :area "470" :service "tv")

;; if set `nhk-program->servie` and `nhk-program->area`, args will be optional.
(nhk-program:list)
(nhk-program:list :tomorrow? t)
(nhk-program:now-on-air)
```

### for Helm

#### Get program list.

```
M-x nhk-program:helm:list
```

![](https://github.com/gongo/emacs-nhk-program/raw/master/images/nhk-program-helm-list.png)

Select program and enter the `<ENTER>`:

![](https://github.com/gongo/emacs-nhk-program/raw/master/images/nhk-program-helm-show.png)

If you want list of tomorrow:

```
C-u M-x nhk-program:helm:list
```

![](https://github.com/gongo/emacs-nhk-program/raw/master/images/nhk-program-helm-tomorrow-list.png)

#### Set `nhk-program->service` and `nhk-program->area`.

e.g.

```
M-x nhk-program:helm:select-area
```

![](https://github.com/gongo/emacs-nhk-program/raw/master/images/nhk-program-select-area.png)

Select area and enter the `<ENTER>`:

![](https://github.com/gongo/emacs-nhk-program/raw/master/images/nhk-program-select-area-show.png)

Other helm actions.

```
M-x nhk-program:helm:now-on-air
M-x nhk-program:helm:select-service
```

License
-------

MIT License
