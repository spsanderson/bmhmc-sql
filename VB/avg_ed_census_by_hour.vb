Option Explicit

 

Sub MatrixFill()

 

    Dim avg_hrl_arr As Double    ' avgerage hourly arrivals

    Dim avg_time_here As Integer ' avgerage time here

    Dim hour_value As Integer    ' the value of the current hour

    Dim y As Integer             ' row iterator for avg_time_here

    Dim xCol As Integer          ' What column to go to

    Dim x As Integer             ' for loop iterator

    Dim LoopCount As Integer     ' How many times the loop has run

    Dim NumCols As Integer       ' How many columns to fill out

    Dim i As Integer             ' if statement for loop iterator

   

    y = 2

    LoopCount = 0

   

    Worksheets("Sheet2").Select

    Worksheets("Sheet2").Activate

   

    ' Clear Matrix

    ActiveSheet.Range("B2:Y25").ClearContents

   

    Do While Cells(y, 27) <> ""

        hour_value = Cells(y, 1)

        avg_time_here = Cells(y, 27)

        NumCols = avg_time_here

        avg_hrl_arr = Cells(y, 28)

        'MsgBox ("The hour = " & hour_value & vbNewLine & "There are on average " & avg_hrl_arr & " hourly arrivals." & vbNewLine & "Avg time here = " & avg_time_here & " hours.")

        xCol = (avg_time_here + hour_value + 1)

        ' loop through columns

        Debug.Print "Hour Value Initialized to: " & hour_value

        Debug.Print "Average Time Here Initialized to: " & avg_time_here

        Debug.Print "NumCols Initialized to: " & NumCols

        Debug.Print "Average Hourly Arrivals Initialized to: " & avg_hrl_arr

        Debug.Print "xCol Initialized to: " & xCol

        For x = (hour_value + 2) To xCol

            Debug.Print "X is currently " & x

            If x > 25 Then

                Debug.Print "NumCols is currently " & NumCols

                i = 2

                Do While NumCols > 0

                    Cells(y, i) = avg_hrl_arr

                    NumCols = NumCols - 1

                    Debug.Print "NumCols is now " & NumCols

                   i = i + 1

                Loop

                GoTo NextYValue

            End If

            Cells(y, x) = avg_hrl_arr

            LoopCount = LoopCount + 1

            NumCols = NumCols - 1

            Debug.Print "Y = " & y

            Debug.Print "LoopCount = " & LoopCount

            Debug.Print "NumCols = " & NumCols & " left"

        Next x

NextYValue:

        y = y + 1

        LoopCount = 0

    Loop

 

End Sub