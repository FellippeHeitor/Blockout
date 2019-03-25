CONST true = -1, false = 0

DIM gameArea AS LONG
gameArea = _NEWIMAGE(400, 500, 32)
SCREEN gameArea
_TITLE "Blockout"
_PRINTMODE _KEEPBACKGROUND

TYPE Block
    x AS INTEGER
    y AS INTEGER
    c AS _UNSIGNED LONG
    state AS _BYTE
END TYPE

TYPE Ball
    x AS SINGLE
    y AS SINGLE
    c AS _UNSIGNED LONG
    radius AS INTEGER
    state AS _BYTE
    xDir AS _BYTE
    yDir AS _BYTE
    xVel AS SINGLE
    yVel AS SINGLE
END TYPE

CONST blockWidth = 50
CONST blockHeight = 25
CONST paddleHeight = 10

DIM SHARED block(1 TO 80) AS Block, ball AS Ball
DIM SHARED win AS _BYTE, quit AS STRING * 1
DIM SHARED paddleX AS INTEGER, paddleY AS INTEGER
DIM SHARED paddleWidth AS INTEGER
DIM SHARED score AS INTEGER, lives AS INTEGER

paddleY = _HEIGHT - blockHeight - paddleHeight - 1

DO
    IF lives = 0 THEN score = 0: lives = 3
    win = false
    generateBlocks
    paddleWidth = 100
    ball.state = false
    ball.c = _RGB32(161, 161, 155)
    ball.radius = 5
    ball.xDir = 1
    ball.yDir = -1
    ball.xVel = 3
    ball.yVel = 3

    _MOUSEHIDE
    _KEYCLEAR

    DO
        alpha = map(ball.xVel, 3, 6, 255, 30)
        LINE (0, 0)-(_WIDTH, _HEIGHT), _RGBA32(0, 0, 0, alpha), BF
        showBlocks
        doPaddle
        doBall

        m$ = "Score:" + STR$(score) + " Lives:" + STR$(lives)
        COLOR _RGB32(0, 0, 0)
        _PRINTSTRING (1, 1), m$
        COLOR _RGB32(255, 255, 255)
        _PRINTSTRING (0, 0), m$

        _DISPLAY
        _LIMIT 60
    LOOP UNTIL win OR lives = 0

    _MOUSESHOW

    CLS
    IF win THEN
        PRINT "Good job, you win."
    ELSE
        PRINT "You lose."
    END IF

    PRINT "Continue (y/n)?"
    _AUTODISPLAY

    DO
        quit = LCASE$(INPUT$(1))
    LOOP UNTIL quit = "y" OR quit = "n"

LOOP WHILE quit = "y"

SYSTEM

SUB generateBlocks
    FOR i = 1 TO 8
        FOR j = 1 TO 10
            b = b + 1
            block(b).x = (i - 1) * blockWidth
            block(b).y = (j - 1) * blockHeight
            block(b).c = _RGB32(255 * RND, 255 * RND, 255 * RND)
            block(b).state = RND
        NEXT
    NEXT
END SUB

SUB showBlocks
    win = true
    FOR i = 1 TO 80
        IF block(i).state = false THEN _CONTINUE
        win = false
        LINE (block(i).x, block(i).y)-STEP(blockWidth - 1, blockHeight - 1), block(i).c, BF
        LINE (block(i).x, block(i).y)-STEP(blockWidth - 1, blockHeight - 1), _RGB32(0, 0, 0), B
    NEXT
END SUB

SUB doPaddle
    STATIC lastX AS INTEGER
    WHILE _MOUSEINPUT: WEND

    IF _MOUSEX <> lastX THEN
        lastX = _MOUSEX
        paddleX = _MOUSEX - paddleWidth / 2
    END IF

    IF _KEYDOWN(19200) THEN paddleX = paddleX - 5
    IF _KEYDOWN(19712) THEN paddleX = paddleX + 5

    IF paddleX < 0 THEN paddleX = 0
    IF paddleX + paddleWidth > _WIDTH - 1 THEN paddleX = _WIDTH - 1 - paddleWidth

    LINE (paddleX + paddleHeight / 2, paddleY)-STEP(paddleWidth - paddleHeight, paddleHeight), _RGB32(89, 161, 255), BF
    CircleFill paddleX + paddleHeight / 2, paddleY + paddleHeight / 2, paddleHeight / 2, _RGB32(194, 89, 61)
    CircleFill paddleX + paddleWidth - paddleHeight / 2, paddleY + paddleHeight / 2, paddleHeight / 2, _RGB32(194, 89, 61)
    IF _MOUSEBUTTON(1) OR _KEYDOWN(13) THEN ball.state = true
END SUB

SUB doBall
    IF ball.state = false THEN
        ball.x = paddleX + paddleWidth / 2
        ball.y = paddleY - (ball.radius)
    ELSE
        ball.x = ball.x + ball.xDir * ball.xVel
        ball.y = ball.y + ball.yDir * ball.yVel

        checkCollision
    END IF
    CircleFill ball.x, ball.y, ball.radius, ball.c
END SUB

SUB checkCollision
    'paddle
    IF ball.x > paddleX AND ball.x < paddleX + paddleWidth AND ball.y > paddleY AND ball.y < paddleY + paddleHeight THEN
        IF ball.x < paddleX + paddleWidth / 2 THEN
            ball.xDir = -1
            ball.xVel = map(ball.x, paddleX, paddleX + paddleWidth / 3, 6, 3)
        ELSE
            ball.xDir = 1
            ball.xVel = map(ball.x, paddleX + paddleWidth / 3, paddleX + paddleWidth, 3, 6)
        END IF
        IF ball.xVel < 3 THEN ball.xVel = 3

        IF ball.yDir = 1 AND ball.y < paddleY + paddleHeight / 2 THEN ball.yDir = -1
        EXIT SUB
    END IF

    'blocks
    FOR i = 1 TO 80
        IF block(i).state = false THEN _CONTINUE
        IF ball.x > block(i).x AND ball.x < block(i).x + blockWidth AND ball.y > block(i).y AND ball.y < block(i).y + blockHeight THEN
            block(i).state = false
            IF ball.x < block(i).x + blockWidth / 2 THEN ball.xDir = -1 ELSE ball.xDir = 1
            IF ball.y < block(i).y + blockHeight / 2 THEN ball.yDir = -1 ELSE ball.yDir = 1
            points = ((_RED32(block(i).c) + _GREEN32(block(i).c) + _BLUE32(block(i).c)) / 3) / 10
            score = score + points
            EXIT SUB
        END IF
    NEXT

    'walls
    IF ball.x < ball.radius THEN ball.xDir = 1
    IF ball.x > _WIDTH - ball.radius THEN ball.xDir = -1
    IF ball.y > _HEIGHT + ball.radius THEN
        lives = lives - 1
        ball.state = false
        ball.xDir = 1
        ball.yDir = -1
        ball.xVel = 3
        ball.yVel = 3
    END IF
    IF ball.y < 0 THEN ball.yDir = 1
END SUB

SUB CircleFill (CX AS INTEGER, CY AS INTEGER, R AS INTEGER, C AS _UNSIGNED LONG)
    ' CX = center x coordinate
    ' CY = center y coordinate
    '  R = radius
    '  C = fill color
    DIM Radius AS INTEGER, RadiusError AS INTEGER
    DIM X AS INTEGER, Y AS INTEGER
    Radius = ABS(R)
    RadiusError = -Radius
    X = Radius
    Y = 0
    IF Radius = 0 THEN PSET (CX, CY), C: EXIT SUB
    LINE (CX - X, CY)-(CX + X, CY), C, BF
    WHILE X > Y
        RadiusError = RadiusError + Y * 2 + 1
        IF RadiusError >= 0 THEN
            IF X <> Y + 1 THEN
                LINE (CX - Y, CY - X)-(CX + Y, CY - X), C, BF
                LINE (CX - Y, CY + X)-(CX + Y, CY + X), C, BF
            END IF
            X = X - 1
            RadiusError = RadiusError - X * 2
        END IF
        Y = Y + 1
        LINE (CX - X, CY - Y)-(CX + X, CY - Y), C, BF
        LINE (CX - X, CY + Y)-(CX + X, CY + Y), C, BF
    WEND
END SUB

FUNCTION map! (value!, minRange!, maxRange!, newMinRange!, newMaxRange!)
    map! = ((value! - minRange!) / (maxRange! - minRange!)) * (newMaxRange! - newMinRange!) + newMinRange!
END FUNCTION

