(use-modules (chickadee)
             (chickadee math vector)
             (chickadee math rect)
             (chickadee audio)
             (chickadee graphics sprite)
             (chickadee graphics texture)
             (chickadee graphics tile-map)
             (chickadee graphics font)
             (sdl2 input keyboard)
             (ice-9 match)
             (ice-9 textual-ports)
             (sxml simple)
             (sxml xpath))

;; Constants
(define audio #f)
(define music-source #f)
(define window-width 512)
(define window-height 512)
(define maze-num-xml 3)
(define sprite-start-x 256.0)
(define sprite-start-y 0.0)
(define camera (vec2 0.0 0.0))
(define current-map #f)
(define current-maze-name #f)
(define requested-maze-name #f)
(define orange-maze-name "orange")
(define green-maze-name "green")
(define final-maze-name "final")
(define current-maze-file #f)
(define green-maze-file "maps/maze-green-filled.tmx")
(define orange-maze-file "maps/maze-orange-filled.tmx")
(define final-maze-file "maps/final.tmx")
(define maze-map-matrix #f)
;;State
(define sprite-left #f)
(define sprite-right #f)
(define sprite-special-left #f)
(define sprite-special-right #f)
(define sprite-rect #f)
(define sprite #f)
(define sprite-x #f)
(define sprite-y #f)
(define tile-x #f)
(define tile-y #f)



(define (strip-string text)
    (substring text 1 (- (string-length text) 1))
)

(define (csv->vector csv-string)
   (list->vector (string-split csv-string #\,))
)

(define (csv->matrix csv-text)
  ;; Split csv text to rows by newline
  (define csv-strings (string-split (strip-string csv-text) #\newline))
  ;; Create vector
  (list->vector (reverse (map csv->vector csv-strings)))
)

;; Read map to SXML format
(define (read-xml port)
   (xml->sxml (get-string-all port))
)

(define (map-layer->matrix map-filepath layer-id)

    (define xml-map (call-with-input-file map-filepath read-xml))
    (define csv-text (list-ref ((sxpath '(// map layer data *text*)) xml-map) layer-id))
    
    (csv->matrix csv-text)    
)

(define (coords vecvec x y)
   (vector-ref (vector-ref vecvec y) x)
)

(define (update-tile-coordinates x y)
;; todo: take a look at recieve function instead of call-with-values...
    (call-with-values 
        (lambda() (point->tile current-map x y))
        (lambda(tx ty) (begin 
                        (set! tile-x tx)
                        (set! tile-y ty))))
)

(define (isallowed? x y)
   (call-with-values
       (lambda() (point->tile current-map x y))
       (lambda(tx ty) (equal? "0" (coords maze-map-matrix tx ty))))
)

(define (move key)
   (begin
   (match key
    ('right (begin
              (let ((new-x (+ (rect-x sprite-rect) 16.0)))
               (if (and (< new-x (- window-width 1.0))
                        (isallowed? new-x (rect-y sprite-rect)))
                (set-rect-x! sprite-rect new-x)))))
    ('left (begin
             (let ((new-x (- (rect-x sprite-rect) 16.0)))
              (if (and (> new-x 0.0)
                       (isallowed? new-x (rect-y sprite-rect)))
                (set-rect-x! sprite-rect new-x)))))
    ('up (begin
             (let ((new-y (+ (rect-y sprite-rect) 16.0)))
                (cond
                  [(and (< new-y (- window-height 1.0)) 
                        (isallowed? (rect-x sprite-rect) new-y)) 
                    (set-rect-y! sprite-rect new-y)]
                  [(and (> new-y (- window-height 1.0))
                        (equal? current-maze-name green-maze-name)) 
                    (begin
                      (set! requested-maze-name orange-maze-name)
                      (set-rect-y! sprite-rect 0.0)                    
                    
                    )]
                  [(and (> new-y (- window-height 1.0))
                        (equal? current-maze-name orange-maze-name)) 
                    (begin
                      (set! requested-maze-name final-maze-name)
                      (set-rect-y! sprite-rect 0.0)                    
                    
                    )]))))
    ('down (begin
             (let ((new-y (- (rect-y sprite-rect) 16.0)))
               (cond
                  [(and (> new-y 0.0) 
                        (isallowed? (rect-x sprite-rect) new-y)) 
                    (set-rect-y! sprite-rect new-y)]
                  [(and (<= new-y 0.0)
                        (equal? current-maze-name orange-maze-name)) 
                    (begin
                      (set! requested-maze-name green-maze-name)
                      (set-rect-y! sprite-rect (- window-height 16.0))                    
                    
                    )]
                  [(and (<= new-y 0.0)
                        (equal? current-maze-name final-maze-name)) 
                    (begin
                      (set! requested-maze-name orange-maze-name)
                      (set-rect-y! sprite-rect (- window-height 16.0))                    
                    
                    )]
                  ;;[(and (<= new-y 0.0)
                  ;;      (equal? current-maze-name green-maze-name)) 
                  ;;  (abort-game)]
                ))))
    (_      #t))
    (update-tile-coordinates (rect-x sprite-rect) (rect-y sprite-rect))
))


(define (key-press key modifiers repeat?)
  (begin
  (match key
    ('right (begin
              (cond
        [(equal? sprite sprite-left) (set! sprite sprite-right)]
        [(equal? sprite sprite-special-left) (set! sprite sprite-special-right)])
               ))
    ('left  (begin
              (cond
        [(equal? sprite sprite-right) (set! sprite sprite-left)]
        [(equal? sprite sprite-special-right) (set! sprite sprite-special-left)])))
    ('space (begin
               (cond
        [(equal? sprite sprite-right) (set! sprite sprite-special-right)]
        [(equal? sprite sprite-left) (set! sprite sprite-special-left)]
        [(equal? sprite sprite-special-right) (set! sprite sprite-right)]
        [(equal? sprite sprite-special-left) (set! sprite sprite-left)])))
    ('q     (abort-game))
    (_      #t))
   (move key)))

(define (load)
  (set! current-maze-file green-maze-file)
  (set! current-map (load-tile-map current-maze-file))
  (set! current-maze-name "green")
  (set! requested-maze-name "green")
  (set! sprite-left (load-image "sprites/be-left.png"))
  (set! sprite-right (load-image "sprites/be-right.png"))
  (set! sprite-special-left (load-image "sprites/be-fly-left.png"))
  (set! sprite-special-right (load-image "sprites/be-fly-right.png"))
  (set! sprite sprite-left)
  (set! sprite-x sprite-start-x)
  (set! sprite-y sprite-start-y)
  (set! sprite-rect (make-rect sprite-x sprite-y 32.0 32.0))
  (set! audio (load-audio "audio/bu-offensive-birds.mp3" #:mode 'stream))
  (set! music-source (make-source #:audio audio))
  (source-play music-source)
  (set! maze-map-matrix (map-layer->matrix current-maze-file maze-num-xml))
)

(define (update dt)
  (when (source-stopped? music-source)
    (begin
      (source-stop music-source)
      (set-source-audio! music-source audio)
      (source-play music-source)
)))

(define (draw alpha)
  (if (not (equal? current-maze-name requested-maze-name)) 
    (begin
       (if (equal? requested-maze-name "orange") 
           (begin (set! current-maze-name "orange")
                  (set! current-maze-file orange-maze-file)
                  (set! current-map (load-tile-map current-maze-file))
                  ))
       (if (equal? requested-maze-name "green") 
           (begin (set! current-maze-name "green")
                  (set! current-maze-file green-maze-file)
                  (set! current-map (load-tile-map current-maze-file))
                  ))
       (if (equal? requested-maze-name "final") 
           (begin (set! current-maze-name "final")
                  (set! current-maze-file final-maze-file)
                  (set! current-map (load-tile-map current-maze-file))
                  ))
     ))
  
  (set! maze-map-matrix (map-layer->matrix current-maze-file maze-num-xml))
  (draw-tile-map current-map #:camera camera)
  (if (equal? current-maze-name "final")
      (draw-text "Some day you'll fly away. But not today, my friend. \nLet's spend some more time together."
             #v(64.0 480.0)))
  (draw-sprite sprite #v((rect-x sprite-rect) (rect-y sprite-rect))))

(run-game #:window-width window-width
          #:window-height window-height
          #:window-title "Birb"
          #:draw draw
          #:update update
          #:key-press key-press
          #:load load)
