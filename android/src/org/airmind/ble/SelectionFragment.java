package org.airmind.ble;

import android.app.Fragment;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import org.mavlink.qgroundcontrol.R;

/**
 * Created by caprin on 16-9-27.
 */

public class SelectionFragment extends Fragment {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View rootView = inflater.inflate(R.layout.fragment_comm_selection,container,false);
        return super.onCreateView(inflater, container, savedInstanceState);
    }
}
