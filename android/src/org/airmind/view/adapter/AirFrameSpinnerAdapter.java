package org.airmind.view.adapter;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.CheckedTextView;
import android.widget.TextView;

import com.airmind.library.airframe.AirframesMetaData;

import java.util.List;

/**
 * Created by KiBa on 2017/2/11.
 */

public class AirFrameSpinnerAdapter extends BaseAdapter {

    private Context context;
    private List<AirframesMetaData.AirFrame> airFrames;

    public AirFrameSpinnerAdapter(Context context, List<AirframesMetaData.AirFrame> airFrames) {
        this.context = context;
        this.airFrames = airFrames;
    }

    @Override
    public int getCount() {
        return airFrames.size();
    }

    @Override
    public AirframesMetaData.AirFrame getItem(int position) {
        return airFrames.get(position);
    }

    @Override
    public long getItemId(int position) {
        return position;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent) {
        ViewHolder viewHolder;
        if(convertView == null){
            viewHolder = new ViewHolder();
            convertView = LayoutInflater.from(context).inflate(android.R.layout.simple_spinner_item, null);
            TextView checkedTextView = (TextView) convertView;
            viewHolder.setCheckedTextView(checkedTextView);
            convertView.setTag(viewHolder);
        }else{
            viewHolder = (ViewHolder) convertView.getTag();
        }

        viewHolder.getCheckedTextView().setText(getItem(position).getName());

        return viewHolder.getCheckedTextView();
    }

    class ViewHolder{
        private TextView checkedTextView;

        public TextView getCheckedTextView() {
            return checkedTextView;
        }

        public void setCheckedTextView(TextView checkedTextView) {
            this.checkedTextView = checkedTextView;
        }
    }

}
