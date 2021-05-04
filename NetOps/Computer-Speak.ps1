#Speaks a message using the Microsoft speech synthesizer

Function Computer-Speak {

    Param([Parameter(Mandatory=$True)][String]$message)

    [Reflection.Assembly]::LoadWithPartialName('System.Speech') | Out-Null
    $synth = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
    $synth.Volume = 100
    $synth.Speak($message)

}