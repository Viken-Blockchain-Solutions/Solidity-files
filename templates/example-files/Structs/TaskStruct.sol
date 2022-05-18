// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract TaskStruct {

    struct Task {
        uint8 status;
        string name;
    }

    Task[] public tasks;

    function createTask(string memory _name) external {
        tasks.push(Task(0, _name));
    }
    
    function updateTaskName(uint _index, string memory _name) external {
        tasks[_index].name = _name;
    }

    function updateTaskStatus(uint _index, uint8 _status) external {
        tasks[_index].status = _status;
    }

    function getTasks() external view returns (Task[] memory) {
        return tasks;
    }

}