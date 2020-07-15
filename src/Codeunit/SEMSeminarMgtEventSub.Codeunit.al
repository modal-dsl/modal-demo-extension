codeunit 50130 "SEM Seminar Mgt. Event Sub."
{
    var
        LastResEntryNo: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Res. Jnl.-Post Line", 'OnBeforeResLedgEntryInsert', '', true, false)]
    local procedure ResJnlPostLineOnBeforeResLedgEntryInsert(var ResLedgerEntry: Record "Res. Ledger Entry"; ResJournalLine: Record "Res. Journal Line")
    begin
        LastResEntryNo := ResLedgerEntry."Entry No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEM Seminar-Post", 'OnPostHeader', '', true, false)]
    local procedure SeminarPostOnPostHeader(var SemRegHeader: Record "SEM Sem. Reg. Header"; var PstdSemRegHeader: Record "SEM Pstd. Sem. Reg. Header"; TempSemRegLineGlobal: Record "SEM Sem. Reg. Line" temporary; SrcCode: Code[10]; CommitIsSuppressed: Boolean; PreviewMode: Boolean)
    begin
        // Instructor
        PostResJnlLine(0, SemRegHeader, PstdSemRegHeader, SrcCode);
        PostSeminarJnlLine(0, SemRegHeader, PstdSemRegHeader, TempSemRegLineGlobal, SrcCode);

        // Room
        PostResJnlLine(1, SemRegHeader, PstdSemRegHeader, SrcCode);
        PostSeminarJnlLine(1, SemRegHeader, PstdSemRegHeader, TempSemRegLineGlobal, SrcCode);
    end;

    local procedure PostResJnlLine(ChargeType: Option Instructor,Room; SeminarRegHeader: Record "SEM Sem. Reg. Header"; PstdSemRegHeader: Record "SEM Pstd. Sem. Reg. Header"; SrcCode: Code[10])
    var
        Instr: Record "SEM Instructor";
        InstrRes: Record Resource;
        SemRoom: Record "SEM Seminar Room";
        RoomRes: Record Resource;
        ResJnlLine: Record "Res. Journal Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
    begin
        with SeminarRegHeader do begin
            ResJnlLine.Init;
            ResJnlLine."Entry Type" := ResJnlLine."Entry Type"::Usage;
            ResJnlLine."Document No." := PstdSemRegHeader."No.";
            ResJnlLine."Posting Date" := "Posting Date";
            ResJnlLine.Description := "Sem. Description";
            ResJnlLine."Source Code" := SrcCode;
            ResJnlLine."Reason Code" := "Reason Code";
            ResJnlLine."Gen. Prod. Posting Group" := "Gen. Prod. Posting Group";
            ResJnlLine."Document Date" := "Document Date";
            ResJnlLine."Posting No. Series" := "Posting No. Series";
            case ChargeType of
                ChargeType::Instructor:
                    begin
                        if Instr.Code <> "Instructor Code" then
                            Instr.Get("Instructor Code");
                        if InstrRes."No." <> Instr."Resource No." then
                            InstrRes.Get(Instr."Resource No.");
                        ResJnlLine."Resource No." := Instr."Resource No.";
                        ResJnlLine."Unit of Measure Code" := InstrRes."Base Unit of Measure";
                        ResJnlLine.Quantity := "Duration Days";
                        ResJnlLine."Qty. per Unit of Measure" := 1;
                        ResJnlLine."Unit Cost" := InstrRes."Unit Cost";
                    end;
                ChargeType::Room:
                    begin
                        if SemRoom.Code <> "Room Code" then
                            SemRoom.Get("Room Code");
                        if RoomRes."No." <> SemRoom."Resource No." then
                            RoomRes.Get(SemRoom."Resource No.");
                        ResJnlLine."Resource No." := SemRoom."Resource No.";
                        ResJnlLine."Unit of Measure Code" := RoomRes."Base Unit of Measure";
                        ResJnlLine.Quantity := "Duration Days";
                        ResJnlLine."Qty. per Unit of Measure" := 1;
                        ResJnlLine."Unit Cost" := RoomRes."Unit Cost";
                    end;
            end;
            ResJnlPostLine.RunWithCheck(ResJnlLine);
        end;
    end;

    local procedure PostSeminarJnlLine(ChargeType: Option Instructor,Room,Participant; SeminarRegHeader: Record "SEM Sem. Reg. Header"; PstdSeminarRegHeader: Record "SEM Pstd. Sem. Reg. Header"; TempSeminarRegLine: Record "SEM Sem. Reg. Line" temporary; SrcCode: Code[10])
    var
        Instr: Record "SEM Instructor";
        SemRoom: Record "SEM Seminar Room";
        SeminarJnlLine: Record "SEM Seminar Journal Line";
        SeminarJnlPostLine: Codeunit "SEM Seminar Jnl.-Post Line";
    begin
        with SeminarRegHeader do begin
            SeminarJnlLine.Init;
            SeminarJnlLine."Seminar No." := "Seminar No.";
            SeminarJnlLine."Posting Date" := "Posting Date";
            SeminarJnlLine."Document Date" := "Document Date";
            SeminarJnlLine."Entry Type" := SeminarJnlLine."Entry Type"::Registration;
            SeminarJnlLine."Document No." := PstdSeminarRegHeader."No.";
            SeminarJnlLine."Starting Date" := "Starting Date";
            SeminarJnlLine."Seminar Registration No." := "No.";
            SeminarJnlLine."Res. Ledger Entry No." := LastResEntryNo;
            LastResEntryNo := 0;
            SeminarJnlLine."Source Type" := SeminarJnlLine."Source Type"::"Seminar Registration";
            SeminarJnlLine."Source No." := "Seminar No.";
            SeminarJnlLine."Source Code" := SrcCode;
            SeminarJnlLine."Reason Code" := "Reason Code";
            SeminarJnlLine."Posting No. Series" := "Posting No. Series";
            SeminarJnlLine."Charge Type" := ChargeType;
            case ChargeType of
                ChargeType::Instructor:
                    begin
                        SeminarJnlLine.Chargeable := false;
                        Instr.Get("Instructor Code");
                        SeminarJnlLine."Instructor Code" := "Instructor Code";
                        SeminarJnlLine.Description := Instr.Name;
                        SeminarJnlLine.Quantity := "Duration Days";
                    end;
                ChargeType::Room:
                    begin
                        SeminarJnlLine.Chargeable := false;
                        SemRoom.Get("Room Code");
                        SeminarJnlLine."Seminar Room Code" := "Room Code";
                        SeminarJnlLine.Description := SemRoom.Name;
                        SeminarJnlLine.Quantity := "Duration Days";
                    end;
                ChargeType::Participant:
                    begin
                        TempSeminarRegLine.CalcFields("Participant Name");
                        SeminarJnlLine.Description := TempSeminarRegLine."Participant Name";
                        SeminarJnlLine."Participant Contact No." := TempSeminarRegLine."Participant Contact No.";
                        SeminarJnlLine."Participant Name" := TempSeminarRegLine."Participant Name";
                        SeminarJnlLine."Bill-to Customer No." := TempSeminarRegLine."Bill-to Customer No.";
                        SeminarJnlLine.Quantity := 1;
                        SeminarJnlLine."Unit Price" := TempSeminarRegLine."Line Amount (LCY)";
                        SeminarJnlLine."Total Price" := TempSeminarRegLine."Line Amount (LCY)";
                        SeminarJnlLine.Chargeable := TempSeminarRegLine."To Invoice";
                    end;
            end;

            SeminarJnlPostLine.RunWithCheck(SeminarJnlLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEM Seminar-Post", 'OnCheckNothingToPost', '', true, false)]
    local procedure SeminarPostOnCheckNothingToPost(var SemRegHeader: Record "SEM Sem. Reg. Header"; var TempSemRegLineGlobal: Record "SEM Sem. Reg. Line" temporary)
    var
        NothingToPostErr: Label 'There is nothing to post.';
    begin
        TempSemRegLineGlobal.SetRange("To Invoice", true);
        if TempSemRegLineGlobal.IsEmpty() then
            Error(NothingToPostErr);

        TempSemRegLineGlobal.SetRange("To Invoice");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEM Seminar-Post", 'OnCheckPostRestrictions', '', true, false)]
    local procedure SeminarPostOnCheckPostRestrictions(var SemRegHeader: Record "SEM Sem. Reg. Header")
    var
        Instr: Record "SEM Instructor";
        SemRoom: Record "SEM Seminar Room";
    begin
        // Instructor
        Instr.Get(SemRegHeader."Instructor Code");
        Instr.TestField(Blocked, false);
        Instr.TestField("Resource No.");

        // Room
        SemRoom.Get(SemRegHeader."Room Code");
        SemRoom.TestField(Blocked, false);
        SemRoom.TestField("Resource No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEM Seminar-Post", 'OnAfterCheckMandatoryFields', '', true, false)]
    local procedure SeminarPostOnAfterCheckMandatoryFields(var SemRegHeader: Record "SEM Sem. Reg. Header"; CommitIsSuppressed: Boolean)
    begin
        with SemRegHeader do begin
            TestField(Status, SemRegHeader.Status::Closed);
            TestField("Instructor Code");
            TestField("Room Code");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEM Seminar-Post", 'OnTestLine', '', true, false)]
    local procedure SeminarPostOnTestLine(var SemRegHeader: Record "SEM Sem. Reg. Header"; var SemRegLine: Record "SEM Sem. Reg. Line"; CommitIsSuppressed: Boolean)
    begin
        with SemRegLine do begin
            TestField("Participant Contact No.");
            TestField("Registration Date");

            if "To Invoice" then begin
                TestField("Seminar Price");
                TestField("Line Amount (LCY)");
                TestField("Gen. Bus. Posting Group");
                TestField("Bill-to Customer No.");
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEM Seminar-Post", 'OnUpdateLineBeforePost', '', true, false)]
    local procedure SeminarPostOnUpdateLineBeforePost(var SemRegHeader: Record "SEM Sem. Reg. Header"; var SemRegLine: Record "SEM Sem. Reg. Line"; CommitIsSuppressed: Boolean)
    begin
        if not SemRegLine."To Invoice" then begin
            SemRegLine."Seminar Price" := 0;
            SemRegLine."Line Amount (LCY)" := 0;
            SemRegLine."Line Discount %" := 0;
            SemRegLine."Line Discount Amount (LCY)" := 0;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEM Seminar-Post", 'OnBeforePostedLineInsert', '', true, false)]
    local procedure SeminarPostOnBeforePostedLineInsert(var PstdSemRegLine: Record "SEM Pstd. Sem. Reg. Line"; PstdSemRegHeader: Record "SEM Pstd. Sem. Reg. Header"; var TempSemRegLineGlobal: Record "SEM Sem. Reg. Line" temporary; SemRegHeader: Record "SEM Sem. Reg. Header"; SrcCode: Code[10]; CommitIsSuppressed: Boolean)
    begin
        // Participant
        PostSeminarJnlLine(2, SemRegHeader, PstdSemRegHeader, TempSemRegLineGlobal, SrcCode);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEM Seminar-Post", 'OnPostUpdatePostedLineOnBeforeModify', '', true, false)]
    local procedure SeminarPostOnPostUpdatePostedLineOnBeforeModify(var SemRegLine: Record "SEM Sem. Reg. Line"; var TempSemRegLine: Record "SEM Sem. Reg. Line" temporary)
    begin
        SemRegLine.Registered := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEM Seminar Jnl.-Check Line", 'OnAfterRunCheck', '', true, false)]
    local procedure SeminarJnlCheckLineOnAfterRunCheck(var SemJnlLine: Record "SEM Seminar Journal Line")
    begin
        with SemJnlLine do begin
            TestField("Document No.");
            TestField("Seminar Registration No.");

            case "Charge Type" of
                "Charge Type"::Instructor:
                    begin
                        TestField("Instructor Code");
                    end;
                "Charge Type"::Participant:
                    begin

                        TestField("Participant Contact No.");
                        TestField("Participant Name");
                    end;
                "Charge Type"::Room:
                    begin
                        TestField("Seminar Room Code");
                    end;
            end;

            if Chargeable then
                TestField("Bill-to Customer No.");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEM Seminar Jnl.-Post Line", 'OnBeforePostJnlLine', '', true, false)]
    local procedure SeminarJnlPostLineOnBeforePostJnlLine(var SemJnlLine: Record "SEM Seminar Journal Line")
    var
        Res: Record Resource;
        Instructor: Record "SEM Instructor";
        SeminarRoom: Record "SEM Seminar Room";
        SeminarRegHeader: Record "SEM Sem. Reg. Header";
        Cust: Record Customer;
    begin
        with SemJnlLine do begin
            case "Charge Type" of
                "Charge Type"::Instructor:
                    begin
                        TestField("Instructor Code");
                        Instructor.Get("Instructor Code");
                        Instructor.TestField(Blocked, false);
                        Res.Get(Instructor."Resource No.");
                        Res.CheckResourcePrivacyBlocked(true);
                        Res.TestField(Blocked, false);
                        Res.TestField("Gen. Prod. Posting Group");
                    end;
                "Charge Type"::Participant:
                    begin
                        TestField("Participant Contact No.");
                        TestField("Participant Name");
                    end;
                "Charge Type"::Room:
                    begin
                        TestField("Seminar Room Code");
                        SeminarRoom.Get("Seminar Room Code");
                        SeminarRoom.TestField(Blocked, false);
                        Res.Get(SeminarRoom."Resource No.");
                        Res.CheckResourcePrivacyBlocked(true);
                        Res.TestField(Blocked, false);
                        Res.TestField("Gen. Prod. Posting Group");
                    end;
            end;

            if "Seminar Registration No." <> '' then begin
                SeminarRegHeader.Get("Seminar Registration No.");
                SeminarRegHeader.TestField("Gen. Prod. Posting Group");
            end;

            if Chargeable then begin
                Cust.Get("Bill-to Customer No.");
                // check invoice posting
                Cust.CheckBlockedCustOnJnls(Cust, 2, true);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"SEM Seminar Journal Line", 'OnBeforeEmptyLine', '', true, false)]
    local procedure SemJnlLineOnBeforeEmptyLine(SemJnlLine: Record "SEM Seminar Journal Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
        IsHandled := true;
        Result := ((SemJnlLine."Seminar No." = '') and (SemJnlLine."Total Price" = 0));
    end;

    [EventSubscriber(ObjectType::Table, Database::"SEM Seminar Ledger Entry", 'OnAfterCopySemLedgerEntryFromSemJnlLine', '', true, false)]
    local procedure SemLedgerEntryOnAfterCopySemLedgerEntryFromSemJnlLine(var SemLedgerEntry: Record "SEM Seminar Ledger Entry"; var SemJnlLine: Record "SEM Seminar Journal Line")
    begin
        with SemLedgerEntry do begin
            "Entry Type" := SemJnlLine."Entry Type";
            "Bill-to Customer No." := SemJnlLine."Bill-to Customer No.";
            "Charge Type" := SemJnlLine."Charge Type";
            Quantity := SemJnlLine.Quantity;
            "Unit Price" := SemJnlLine."Unit Price";
            "Total Price" := SemJnlLine."Total Price";
            "Participant Contact No." := SemJnlLine."Participant Contact No.";
            "Participant Name" := SemJnlLine."Participant Name";
            Chargeable := SemJnlLine.Chargeable;
            "Seminar Room Code" := SemJnlLine."Seminar Room Code";
            "Instructor Code" := SemJnlLine."Instructor Code";
            "Starting Date" := SemJnlLine."Starting Date";
            "Seminar Registration No." := SemJnlLine."Seminar Registration No.";
            "Res. Ledger Entry No." := SemJnlLine."Res. Ledger Entry No.";
            "Source Type" := SemJnlLine."Source Type";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"SEM Sem. Reg. Line", 'OnAfterInitRecord', '', true, false)]
    local procedure SemRegLineOnAfterInitRecord(var SemRegLine: Record "SEM Sem. Reg. Line"; var SemRegHeader: Record "SEM Sem. Reg. Header")
    begin
        with SemRegLine do begin
            If "Registration Date" = 0D then
                "Registration Date" := WorkDate();

            Validate("Seminar Price", SemRegHeader."Seminar Price");
            "External Document No." := SemRegHeader."External Document No.";
            "To Invoice" := true;
        end;
    end;

}