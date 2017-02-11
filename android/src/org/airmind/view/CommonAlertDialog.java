package org.airmind.view;

import android.app.Activity;
import android.content.DialogInterface;
import android.support.v7.app.AlertDialog;

/**
 * Created by KiBa on 2017/1/4.
 */

public class CommonAlertDialog{

    private Activity context;
    private DialogInterface.OnClickListener positiveListener;
    private DialogInterface.OnClickListener negativeListener;
    private DialogInterface.OnDismissListener dismissListener;
    private AlertDialog.Builder builder;
    private AlertDialog alertDialog;

    protected CommonAlertDialog(Activity context, int themeResId, String message) {
        this.context = context;
        init(message, themeResId);
    }

    protected CommonAlertDialog(Activity context, String message) {
        this.context = context;
        init(message, 0);
    }

    private void init(String message, int themeResId){
        builder = new AlertDialog.Builder(getContext());
        builder.setMessage(message);
        builder.setPositiveButton("OK", new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialogInterface, int i) {
                positiveListener.onClick(dialogInterface, i);
            }
        });
        builder.setNegativeButton("Cancel", negativeListener);
        builder.setOnDismissListener(dismissListener);
        alertDialog = builder.create();
    }

    public void show(){
        if(alertDialog != null && !alertDialog.isShowing()){
            alertDialog.show();
        }
    }

    public void dismiss(){
        if(alertDialog != null && alertDialog.isShowing()){
            alertDialog.dismiss();
        }
    }

    public void setPositiveListener(DialogInterface.OnClickListener positiveListener) {
        this.positiveListener = positiveListener;
    }

    public void setNegativeListener(DialogInterface.OnClickListener negativeListener) {
        this.negativeListener = negativeListener;
    }

    public void setDismissListener(DialogInterface.OnDismissListener dismissListener) {
        this.dismissListener = dismissListener;
    }

    public Activity getContext() {
        return context;
    }

    public DialogInterface.OnClickListener getPositiveListener() {
        return positiveListener;
    }

    public DialogInterface.OnClickListener getNegativeListener() {
        return negativeListener;
    }

    public DialogInterface.OnDismissListener getDismissListener() {
        return dismissListener;
    }
}
