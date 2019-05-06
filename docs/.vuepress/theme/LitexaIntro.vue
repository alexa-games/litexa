<template>
  <div class='litexa'>
        <div class='litexa-script'>
        <table class='litexa-turn litexa-'>
            <tr>
            <td><i class='litexa-label'>player:</i></td>
            <td><span class='litexa-user '> <span class='litexa-intent '>LaunchIntent</span> "launch my game"
                </span></td>
            </tr>
            <tr>
            <td><i class='litexa-label'>alexa:</i></td>
            <td><span class='litexa-response litexa-'> <span class='litexa-alexa '>Hi there!</span>&nbsp;<span
                    class='litexa-arrow'>➡</span>&nbsp;<span class='litexa-alexa litexa-question'>How many people are
                    playing today?</span> </span></td>
            </tr>
        </table>
        <table class='litexa-turn litexa-routing'>
            <tr>
            <td><i class='litexa-label'>player:</i></td>
            <td><span class='litexa-user litexa-routing'> <span
                    class='litexa-intent litexa-routing'>NUMBER(3)</span> "three" </span></td>
            </tr>
            <tr>
            <td><i class='litexa-label'>alexa:</i></td>
            <td><span class='litexa-response litexa-routing litexa-repeat'> <span
                    class='litexa-alexa '>Great.</span>&nbsp;<span class='litexa-arrow'>➡</span>&nbsp;<span
                    class='litexa-alexa litexa-question litexa-repeat'>Would you like to play with winner takes all
                    rules?</span> </span></td>
            </tr>
        </table>
        <table class='litexa-turn litexa-routing'>
            <tr>
            <td><i class='litexa-label'>player:</i></td>
            <td><span class='litexa-user litexa-routing'> <span
                    class='litexa-intent litexa-routing'>NUMBER(3)</span> "three" </span></td>
            </tr>
            <tr>
            <td><i class='litexa-label'>alexa:</i></td>
            <td><span class='litexa-response litexa-routing litexa-repeat'> <span class='litexa-alexa '>I'm sorry, I
                    didn't understand that.</span>&nbsp;<span class='litexa-arrow'>➡</span>&nbsp;<span
                    class='litexa-alexa litexa-repeat'>Would you like to play with winner takes all rules?</span>
                </span></td>
            </tr>
        </table>
        <table class='litexa-turn litexa-'>
            <tr>
            <td><i class='litexa-label'>player:</i></td>
            <td><span class='litexa-user litexa-sames'> <span
                    class='litexa-intent litexa-sames'>AMAZON.YesIntent</span> "yes" </span></td>
            </tr>
            <tr>
            <td><i class='litexa-label'>alexa:</i></td>
            <td><span class='litexa-response litexa-'> <span class='litexa-alexa '>Noted.</span>&nbsp;<span
                    class='litexa-arrow'>➡</span>&nbsp;<span class='litexa-alexa '>We're ready to
                    start!</span>&nbsp;<span class='litexa-arrow'>➡</span>&nbsp;<span class='litexa-alexa '>Round
                    1.</span>&nbsp;<span class='litexa-arrow'>➡</span>&nbsp;<span class='litexa-alexa '>Player 1. The
                    number of cats in Chicago. Less than or more than 1 million?</span> </span></td>
            </tr>
        </table>
        <table class='litexa-turn litexa-'>
            <tr>
            <td><i class='litexa-label'>player:</i></td>
            <td><span class='litexa-user '> <span class='litexa-intent '>LESSTHAN</span> "less than" </span></td>
            </tr>
            <tr>
            <td><i class='litexa-label'>alexa:</i></td>
            <td><span class='litexa-response litexa-'> <span class='litexa-alexa '>Ok. Next up,</span>&nbsp;<span
                    class='litexa-arrow'>➡</span>&nbsp;<span class='litexa-alexa '>Player 2. The number of cats in
                    Chicago. Less than or more than 1 million?</span> </span></td>
            </tr>
        </table>
        <table class='litexa-turn litexa-'>
            <tr>
            <td><i class='litexa-label'>player:</i></td>
            <td><span class='litexa-user '> <span class='litexa-intent '>AMAZON.RepeatIntent</span> "repeat that"
                </span></td>
            </tr>
            <tr>
            <td><i class='litexa-label'>alexa:</i></td>
            <td><span class='litexa-response litexa-'> <span class='litexa-alexa '>Sure.</span>&nbsp;<span
                    class='litexa-arrow'>➡</span>&nbsp;<span class='litexa-alexa '>Player 2. The number of cats in
                    Chicago. Less than or more than 1 million?</span> </span></td>
            </tr>
        </table>
        <table class='litexa-turn litexa-'>
            <tr>
            <td><i class='litexa-label'>player:</i></td>
            <td><span class='litexa-user '> <span class='litexa-intent '>MORETHAN</span> "more than" </span></td>
            </tr>
            <tr>
            <td><i class='litexa-label'>alexa:</i></td>
            <td><span class='litexa-response litexa-'> <span class='litexa-alexa '>And finally,</span>&nbsp;<span
                    class='litexa-arrow'>➡</span>&nbsp;<span class='litexa-alexa '>Player 3. The number of cats in
                    Chicago. Less than or more than 1 million?</span> </span></td>
            </tr>
        </table>
        <table class='litexa-turn litexa-'>
            <tr>
            <td><i class='litexa-label'>player:</i></td>
            <td><span class='litexa-user '> <span class='litexa-intent '>AMAZON.HelpIntent</span> "help" </span>
            </td>
            </tr>
            <tr>
            <td><i class='litexa-label'>alexa:</i></td>
            <td><span class='litexa-response litexa-'> <span class='litexa-alexa '>All you have to do is tell me
                    whether you guess the real number is higher, or lower than the one in the question. Here we
                    go!</span>&nbsp;<span class='litexa-arrow'>➡</span>&nbsp;<span class='litexa-alexa '>Player 3. The
                    number of cats in Chicago. Less than or more than 1 million?</span> </span></td>
            </tr>
        </table>
        <table class='litexa-turn litexa-'>
            <tr>
            <td><i class='litexa-label'>player:</i></td>
            <td><span class='litexa-user '> <span class='litexa-intent '>LESSTHAN</span> "fewer" </span></td>
            </tr>
            <tr>
            <td><i class='litexa-label'>alexa:</i></td>
            <td><span class='litexa-response litexa-'> <span class='litexa-alexa '>Great! *drummroll
                    sfx*</span>&nbsp;<span class='litexa-arrow'>➡</span>&nbsp;<span class='litexa-alexa '>Aww, too bad
                    players 1 and 3. It turns out there are an estimated 4 million cats in Chicago! That's 3 points
                    for player 2!</span>&nbsp;<span class='litexa-arrow'>➡</span>&nbsp;<span
                    class='litexa-alexa '>Let's move on.</span>&nbsp;<span class='litexa-arrow'>➡</span>&nbsp;<span
                    class='litexa-alexa litexa-round'>Round 2.</span>&nbsp;<span
                    class='litexa-arrow'>➡</span>&nbsp;<span class='litexa-alexa '>Player 1. Chopin's Military
                    Polonaise in A. Was it written before or after the year 1800?</span> </span></td>
            </tr>
        </table>
        <table class='litexa-turn litexa-'>
            <tr>
            <td><i class='litexa-label'>player:</i></td>
            <td><span class='litexa-user '> <span class='litexa-intent '>AMAZON.StopIntent</span> "alexa, stop"
                </span></td>
            </tr>
            <tr>
            <td><i class='litexa-label'>alexa:</i></td>
            <td><span class='litexa-response litexa-'> <span class='litexa-alexa '>Ok. Come back anytime to play,
                    Higher or Lower! *exit music*</span> </span></td>
            </tr>
        </table>
        </div>
        <div class='code litexa-code'>
        <div style="color: #d4d4d4;">
            <div><span style="color: #d4d4d4;text-decoration: underline;">launch </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Hi there!"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">howManyPlayers</span></div><br><br>
            <div><span style="color: #d4d4d4;text-decoration: underline;">howManyPlayers</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"How many people are playing
                today?"</span></div>
            <div><span style="color: #d4d4d4;"> </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">when</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"</span><span
                style="color: #569cd6;">$number</span><span style="color: #ce9178;">"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">with</span><span
                style="color: #d4d4d4;"> </span><span style="color: #569cd6;">$number</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">=</span><span style="color: #d4d4d4;">
            </span><span style="color: #9cdcfe;">AMAZON.NUMBER</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Great."</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@playerCount</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">=</span><span style="color: #d4d4d4;">
            </span><span style="color: #569cd6;">$number</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">askHouseRules</span></div><br><br>
            <div><span style="color: #d4d4d4;text-decoration: underline;">askHouseRules</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Would you like to play with winner
            </span></div>
            <div><span style="color: #ce9178;"> takes all rules?"</span></div><br>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">when</span><span
                style="color: #d4d4d4;"> </span><span style="color: #9cdcfe;">AMAZON.YesIntent</span><span
                style="color: #d4d4d4;"> </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Noted."</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">startGame</span></div><br>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">otherwise</span><span
                style="color: #d4d4d4;"> </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"I'm sorry, I didn't understand
                that."</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">askHouseRules</span></div><br><br>
            <div><span style="color: #d4d4d4;text-decoration: underline;">startGame</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"We're ready to start!"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@round</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">=</span><span style="color: #d4d4d4;">
            </span><span style="color: #b5cea8;">0</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">beginRound</span></div><br><br>
            <div><span style="color: #d4d4d4;text-decoration: underline;">nextRound</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@round</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">=</span><span style="color: #d4d4d4;">
            </span><span style="color: #569cd6;">@round</span><span style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;">+</span><span style="color: #d4d4d4;"> </span><span
                style="color: #b5cea8;">1</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@playerTurn</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">=</span><span style="color: #d4d4d4;">
            </span><span style="color: #b5cea8;">1</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@question</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">=</span><span style="color: #d4d4d4;">
            </span><span style="color: #9cdcfe;">getRandomQuestion</span><span style="color: #d4d4d4;">()</span>
            </div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Round </span><span
                style="color: #569cd6;">@round.</span><span style="color: #ce9178;">"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">askQuestion</span></div><br><br>
            <div><span style="color: #d4d4d4;text-decoration: underline;">askQuestion</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Player </span><span
                style="color: #569cd6;">@playerTurn.</span><span style="color: #ce9178;"> </span><span
                style="color: #569cd6;">@question.spoken</span><span style="color: #ce9178;">"</span></div><br>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">when</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"less than"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Ok."</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #9cdcfe;">setAnswer</span><span
                style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@question</span><span
                style="color: #d4d4d4;">, </span><span style="color: #569cd6;">@playerTurn</span><span
                style="color: #d4d4d4;">, </span><span style="color: #ce9178;">"less"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">nextPlayer</span></div><br>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">when</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"more than"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Great."</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #9cdcfe;">setAnswer</span><span
                style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@question</span><span
                style="color: #d4d4d4;">, </span><span style="color: #569cd6;">@playerTurn</span><span
                style="color: #d4d4d4;">, </span><span style="color: #ce9178;">"more"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">nextPlayer</span></div><br>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">when</span><span
                style="color: #d4d4d4;"> </span><span style="color: #9cdcfe;">AMAZON.RepeatIntent</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Sure."</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">askQuestion</span></div><br>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">when</span><span
                style="color: #d4d4d4;"> </span><span style="color: #9cdcfe;">AMAZON.HelpIntent</span><span
                style="color: #d4d4d4;"> </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"All you have to do is tell me whether
            </span></div>
            <div><span style="color: #ce9178;"> you guess the real number is higher, or </span></div>
            <div><span style="color: #ce9178;"> lower than the one in the question. </span></div>
            <div><span style="color: #ce9178;"> Here we go!"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">askQuestion</span></div><br><br>
            <div><span style="color: #d4d4d4;text-decoration: underline;">nextPlayer </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@playerTurn</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">=</span><span style="color: #d4d4d4;">
            </span><span style="color: #569cd6;">@playerTurn</span><span style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;">+</span><span style="color: #d4d4d4;"> </span><span
                style="color: #b5cea8;">1</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">if</span><span
                style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@playerTurn</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">&gt;</span><span
                style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@playerCount</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">announceResults</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">else</span><span
                style="color: #d4d4d4;"> </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">if</span><span
                style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@playerTurn</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">==</span><span style="color: #d4d4d4;">
            </span><span style="color: #569cd6;">@playerCount</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"And finally,"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">else</span><span
                style="color: #d4d4d4;"> </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Next up,"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">askQuestion</span></div><br>
            <div><span style="color: #d4d4d4;text-decoration: underline;">announceResults</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">soundEffect</span><span
                style="color: #d4d4d4;"> </span><span style="color: #9cdcfe;">drumroll.mp3</span></div><br>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">if</span><span
                style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@question.losers.length</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">&gt;</span><span
                style="color: #d4d4d4;"> </span><span style="color: #b5cea8;">0</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Aww, too bad"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">if</span><span
                style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@question.losers.length</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">==</span><span style="color: #d4d4d4;">
            </span><span style="color: #b5cea8;">1</span><span style="color: #d4d4d4;"> </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Player </span><span
                style="color: #569cd6;">@question.losers</span><span style="color: #ce9178;">[0]"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">else</span><span
                style="color: #d4d4d4;"> </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Players {speakList(</span><span
                style="color: #569cd6;">@question.losers</span><span style="color: #ce9178;">, 'and')}"</span></div>
            <div><span style="color: #d4d4d4;"> </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"</span><span
                style="color: #569cd6;">@question.fact</span><span style="color: #ce9178;">"</span></div><br>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">if</span><span
                style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@question.winners.length</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">&gt;</span><span
                style="color: #d4d4d4;"> </span><span style="color: #b5cea8;">0</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">if</span><span
                style="color: #d4d4d4;"> </span><span style="color: #569cd6;">@question.winners.length</span><span
                style="color: #d4d4d4;"> </span><span style="color: #d4d4d4;">==</span><span style="color: #d4d4d4;">
            </span><span style="color: #b5cea8;">1</span><span style="color: #d4d4d4;"> </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"That's </span><span
                style="color: #569cd6;">@question.points</span><span style="color: #ce9178;"> for Player </span><span
                style="color: #569cd6;">@question.winners</span><span style="color: #ce9178;">[0]!"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">else</span><span
                style="color: #d4d4d4;"> </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"That's </span><span
                style="color: #569cd6;">@question.points</span><span style="color: #ce9178;"> for Players </span>
            </div>
            <div><span style="color: #ce9178;"> {speakList(</span><span
                style="color: #569cd6;">@question.winners</span><span style="color: #ce9178;">, 'and')}"</span></div>
            <br>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Let's move on."</span></div><br>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">-&gt;</span><span
                style="color: #d4d4d4;"> </span><span
                style="color: #d4d4d4;text-decoration: underline;">nextRound</span></div><br><br>
            <div><span style="color: #d4d4d4;text-decoration: underline;">global </span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">when</span><span
                style="color: #d4d4d4;"> </span><span style="color: #9cdcfe;">AMAZON.StopIntent</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">say</span><span
                style="color: #d4d4d4;"> </span><span style="color: #ce9178;">"Ok. Come back anytime to play, </span>
            </div>
            <div><span style="color: #ce9178;"> Higher or Lower!"</span></div>
            <div><span style="color: #d4d4d4;"> </span><span style="color: #c586c0;">soundEffect</span><span
                style="color: #d4d4d4;"> </span><span style="color: #9cdcfe;">exitMusic.mp3</span></div>
        </div>
        </div>
        <div class='litexa-shadow'></div>
        <div class='litexa-note-wrapper'>
        <div class='litexa-note'>alexa script</div>
        </div>
    </div>
</template>

<script>
export default {
  data() {
    return {
      hello: ""
    };
  },

  computed: {},

  methods: {}
};
</script>

<style lang="stylus">
@import './styles/config.styl';


@media (max-width: $MQNarrow) {

}

@media (max-width: $MQNarrow) and (min-width: $MQMobile) {

}

@media (max-width: $MQMobile) {

}

@media (max-width: $MQMobileNarrow) {

}
</style>
